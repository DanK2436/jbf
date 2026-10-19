/**
 * Appels audio/vidéo WebRTC JBF — signalisation via cache local + messages_chat Supabase.
 */
(function (window) {
  'use strict';

  const SIGNAL_PREFIX = '[CALL_SIGNAL]||';
  const LOCAL_SIGNAL_KEY = 'JBF_WEBRTC_SIGNALS';

  function readLocalSignals() {
    try {
      return JSON.parse(localStorage.getItem(LOCAL_SIGNAL_KEY) || '[]');
    } catch (_) {
      return [];
    }
  }

  function writeLocalSignals(list) {
    try {
      localStorage.setItem(LOCAL_SIGNAL_KEY, JSON.stringify(list.slice(-300)));
    } catch (_) {}
  }

  function appendSignal(payload) {
    const list = readLocalSignals();
    list.push({ ...payload, at: Date.now() });
    writeLocalSignals(list);
  }

  function parseSignalMessage(text) {
    if (!text || !String(text).startsWith(SIGNAL_PREFIX)) return null;
    try {
      return JSON.parse(String(text).slice(SIGNAL_PREFIX.length));
    } catch (_) {
      return null;
    }
  }

  function encodeSignalMessage(payload) {
    return SIGNAL_PREFIX + JSON.stringify(payload);
  }

  class JbfPeerCall {
    constructor(options) {
      this.myId = options.myId;
      this.peerId = options.peerId;
      this.isVideo = !!options.isVideo;
      this.onRemoteStream = options.onRemoteStream || (() => {});
      this.onStateChange = options.onStateChange || (() => {});
      this.onError = options.onError || (() => {});
      this.localStream = null;
      this.pc = new RTCPeerConnection({
        iceServers: [
          { urls: 'stun:stun.l.google.com:19302' },
          { urls: 'stun:stun1.l.google.com:19302' }
        ]
      });
      this.pc.ontrack = (ev) => {
        if (ev.streams && ev.streams[0]) this.onRemoteStream(ev.streams[0]);
      };
      this.pc.onicecandidate = (ev) => {
        if (ev.candidate) {
          this._emit({ type: 'ice', candidate: ev.candidate.toJSON() });
        }
      };
      this.pc.onconnectionstatechange = () => {
        this.onStateChange(this.pc.connectionState);
        if (this.pc.connectionState === 'failed' || this.pc.connectionState === 'disconnected') {
          this.onError('Connexion interrompue');
        }
      };
    }

    _emit(body) {
      const payload = {
        type: body.type,
        from: this.myId,
        to: this.peerId,
        callId: this.callId,
        ...body
      };
      appendSignal(payload);
      if (window.JBFCallSignaling?.publish) {
        window.JBFCallSignaling.publish(payload);
      }
    }

    async _attachLocalMedia() {
      this.localStream = await navigator.mediaDevices.getUserMedia({
        audio: true,
        video: this.isVideo
      });
      this.localStream.getTracks().forEach((t) => this.pc.addTrack(t, this.localStream));
      return this.localStream;
    }

    async startOutgoing(callId) {
      this.callId = callId || `call-${Date.now()}`;
      this.onStateChange('calling');
      await this._attachLocalMedia();
      const offer = await this.pc.createOffer();
      await this.pc.setLocalDescription(offer);
      this._emit({ type: 'offer', sdp: offer });
      this.onStateChange('ringing');
    }

    async handleSignal(msg) {
      if (!msg || msg.to !== this.myId && msg.from !== this.peerId) return;
      if (msg.callId && this.callId && msg.callId !== this.callId) return;

      if (msg.type === 'offer') {
        this.callId = msg.callId || this.callId || `call-${Date.now()}`;
        this.onStateChange('incoming');
        await this._attachLocalMedia();
        await this.pc.setRemoteDescription(new RTCSessionDescription(msg.sdp));
        const answer = await this.pc.createAnswer();
        await this.pc.setLocalDescription(answer);
        this._emit({ type: 'answer', sdp: answer, callId: this.callId });
        this.onStateChange('connected');
      } else if (msg.type === 'answer' && msg.sdp) {
        await this.pc.setRemoteDescription(new RTCSessionDescription(msg.sdp));
        this.onStateChange('connected');
      } else if (msg.type === 'ice' && msg.candidate) {
        try {
          await this.pc.addIceCandidate(new RTCIceCandidate(msg.candidate));
        } catch (e) {
          console.warn('[WebRTC ICE]', e);
        }
      } else if (msg.type === 'hangup') {
        this.hangup(false);
      }
    }

    hangup(notifyPeer) {
      if (notifyPeer !== false) {
        this._emit({ type: 'hangup', callId: this.callId });
      }
      if (this.localStream) {
        this.localStream.getTracks().forEach((t) => t.stop());
        this.localStream = null;
      }
      try {
        this.pc.close();
      } catch (_) {}
      this.onStateChange('ended');
    }
  }

  function collectSignalsFor(peerId, myId, sinceMs) {
    const since = sinceMs || Date.now() - 120000;
    return readLocalSignals().filter(
      (s) => s.at >= since && (s.to === myId || s.from === peerId) && (s.from === peerId || s.to === peerId)
    );
  }

  window.JBFWebRTC = {
    SIGNAL_PREFIX,
    parseSignalMessage,
    encodeSignalMessage,
    appendSignal,
    readLocalSignals,
    JbfPeerCall,
    collectSignalsFor
  };
})(window);
