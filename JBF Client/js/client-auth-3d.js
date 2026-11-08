/**
 * =============================================================
 * JBF Client — MULTI-SHAPE 3D WEBGL IMMERSIVE SCENES
 * Formes 3D distinctes et exclusives par écran d'authentification :
 * 1. LOGIN : Cyber Prism Shield & Security Matrix (Cube & Bouclier)
 * 2. SIGN UP : Infinity Torus Knot Helix (Nœud toroïdal d'interconnexion)
 * 3. FORGOT PASSWORD : Stellated Merkaba Star Beacon (Étoile polyédrique de rétablissement)
 * =============================================================
 */

(function () {
  'use strict';

  function initAuth3D() {
    if (typeof THREE === 'undefined') return;

    let canvas = document.getElementById('auth3DCanvas');
    if (!canvas) {
      canvas = document.createElement('canvas');
      canvas.id = 'auth3DCanvas';
      canvas.style.position = 'fixed';
      canvas.style.top = '0';
      canvas.style.left = '0';
      canvas.style.width = '100vw';
      canvas.style.height = '100vh';
      canvas.style.zIndex = '0';
      canvas.style.pointerEvents = 'none';
      canvas.style.opacity = '0.94';
      document.body.prepend(canvas);
    }

    const prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

    // Détection du type de page
    const pathname = (window.location.pathname || '').toLowerCase();
    let pageType = 'login';
    if (pathname.includes('register') || document.body.dataset.authPage === 'register') {
      pageType = 'register';
    } else if (pathname.includes('forgot') || pathname.includes('reset') || document.body.dataset.authPage === 'forgot') {
      pageType = 'forgot';
    }

    let renderer, scene, camera;
    let mainGeometryGroup, innerCore, outerWire, orbitalRings = [], particles;
    let mouse = { x: 0, y: 0, targetX: 0, targetY: 0 };
    let isVisible = true;
    let animId = null;

    function buildAuthScene() {
      const w = window.innerWidth;
      const h = window.innerHeight;

      try {
        renderer = new THREE.WebGLRenderer({
          canvas: canvas,
          alpha: true,
          antialias: true,
          powerPreference: 'high-performance'
        });
      } catch (e) {
        console.warn('[JBF Auth 3D] WebGL non supporté:', e);
        return false;
      }

      renderer.setSize(w, h);
      renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2));
      renderer.setClearColor(0x000000, 0);

      scene = new THREE.Scene();
      camera = new THREE.PerspectiveCamera(45, w / h, 0.1, 100);
      camera.position.set(0, 0, 8.8);

      // Éclairage studio
      const ambientLight = new THREE.AmbientLight(0xffffff, 0.85);
      scene.add(ambientLight);

      const pinkLight = new THREE.PointLight(0xE6007E, 3.2, 35);
      pinkLight.position.set(5, 4, 6);
      scene.add(pinkLight);

      const grayLight = new THREE.PointLight(0xAAAAAA, 2.0, 35);
      grayLight.position.set(-6, -3, 4);
      scene.add(grayLight);

      mainGeometryGroup = new THREE.Group();
      scene.add(mainGeometryGroup);

      // =========================================================
      // FORME 3D 1 : LOGIN — Cyber Prism Shield & Security Matrix
      // =========================================================
      if (pageType === 'login') {
        // Cœur central cubique facetté à biseaux
        const boxGeo = new THREE.BoxGeometry(1.6, 1.6, 1.6);
        const boxMat = new THREE.MeshStandardMaterial({
          color: 0xE6007E,
          metalness: 0.88,
          roughness: 0.22,
          flatShading: true
        });
        innerCore = new THREE.Mesh(boxGeo, boxMat);
        mainGeometryGroup.add(innerCore);

        // Bouclier octaédrique externe filaire
        const shieldGeo = new THREE.OctahedronGeometry(2.35, 0);
        const shieldMat = new THREE.MeshBasicMaterial({
          color: 0xAAAAAA,
          wireframe: true,
          transparent: true,
          opacity: 0.6
        });
        outerWire = new THREE.Mesh(shieldGeo, shieldMat);
        mainGeometryGroup.add(outerWire);

        // Double anneau orthogonal de sécurité
        const r1Geo = new THREE.TorusGeometry(3.0, 0.035, 16, 90);
        const r1Mat = new THREE.MeshBasicMaterial({ color: 0xE6007E, transparent: true, opacity: 0.65 });
        const ringA = new THREE.Mesh(r1Geo, r1Mat);
        ringA.rotation.x = Math.PI / 2;
        orbitalRings.push(ringA);
        mainGeometryGroup.add(ringA);

        const r2Geo = new THREE.TorusGeometry(3.4, 0.025, 16, 90);
        const r2Mat = new THREE.MeshBasicMaterial({ color: 0xCCCCCC, transparent: true, opacity: 0.5 });
        const ringB = new THREE.Mesh(r2Geo, r2Mat);
        ringB.rotation.y = Math.PI / 3;
        orbitalRings.push(ringB);
        mainGeometryGroup.add(ringB);
      }

      // =========================================================
      // FORME 3D 2 : SIGN UP — Infinity Torus Knot Helix
      // =========================================================
      else if (pageType === 'register') {
        // Nœud toroïdal d'interconnexion (Torus Knot)
        const knotGeo = new THREE.TorusKnotGeometry(1.5, 0.38, 128, 20, 2, 3);
        const knotMat = new THREE.MeshStandardMaterial({
          color: 0xE6007E,
          metalness: 0.9,
          roughness: 0.2,
          flatShading: false
        });
        innerCore = new THREE.Mesh(knotGeo, knotMat);
        mainGeometryGroup.add(innerCore);

        // Cage filaire de connexion
        const cageGeo = new THREE.IcosahedronGeometry(2.6, 1);
        const cageMat = new THREE.MeshBasicMaterial({
          color: 0xFF69B4,
          wireframe: true,
          transparent: true,
          opacity: 0.35
        });
        outerWire = new THREE.Mesh(cageGeo, cageMat);
        mainGeometryGroup.add(outerWire);

        // Anneau orbital d'expansion
        const rGeo = new THREE.TorusGeometry(3.5, 0.04, 16, 100);
        const rMat = new THREE.MeshBasicMaterial({ color: 0xAAAAAA, transparent: true, opacity: 0.7 });
        const ring = new THREE.Mesh(rGeo, rMat);
        ring.rotation.x = Math.PI / 4;
        orbitalRings.push(ring);
        mainGeometryGroup.add(ring);
      }

      // =========================================================
      // FORME 3D 3 : FORGOT PASSWORD — Stellated Merkaba Star Beacon
      // =========================================================
      else {
        // Étoile polyédrique (Stellated Octahedron / Merkaba)
        const t1Geo = new THREE.TetrahedronGeometry(1.7, 0);
        const t1Mat = new THREE.MeshStandardMaterial({
          color: 0xE6007E,
          metalness: 0.85,
          roughness: 0.25,
          flatShading: true
        });
        const tetra1 = new THREE.Mesh(t1Geo, t1Mat);

        const t2Geo = new THREE.TetrahedronGeometry(1.7, 0);
        const t2Mat = new THREE.MeshStandardMaterial({
          color: 0x7A1248,
          metalness: 0.85,
          roughness: 0.25,
          flatShading: true
        });
        const tetra2 = new THREE.Mesh(t2Geo, t2Mat);
        tetra2.rotation.x = Math.PI;
        tetra2.rotation.z = Math.PI / 4;

        innerCore = new THREE.Group();
        innerCore.add(tetra1);
        innerCore.add(tetra2);
        mainGeometryGroup.add(innerCore);

        // Sphère filaire balise extérieure
        const starCageGeo = new THREE.DodecahedronGeometry(2.5, 0);
        const starCageMat = new THREE.MeshBasicMaterial({
          color: 0xAAAAAA,
          wireframe: true,
          transparent: true,
          opacity: 0.5
        });
        outerWire = new THREE.Mesh(starCageGeo, starCageMat);
        mainGeometryGroup.add(outerWire);

        // Anneau gyroscopique de réalignement
        const beaconRingGeo = new THREE.TorusGeometry(3.2, 0.035, 16, 90);
        const beaconRingMat = new THREE.MeshBasicMaterial({ color: 0xE6007E, transparent: true, opacity: 0.7 });
        const bRing = new THREE.Mesh(beaconRingGeo, beaconRingMat);
        bRing.rotation.y = Math.PI / 4;
        orbitalRings.push(bRing);
        mainGeometryGroup.add(bRing);
      }

      // Constellation de particules de données (170 nœuds)
      const pCount = 170;
      const positions = new Float32Array(pCount * 3);
      const colors = new Float32Array(pCount * 3);
      const colorPink = new THREE.Color(0xE6007E);
      const colorGray = new THREE.Color(0xAAAAAA);
      const colorWhite = new THREE.Color(0xFFFFFF);

      for (let i = 0; i < pCount; i++) {
        const radius = 2.8 + Math.random() * 5.0;
        const theta = Math.random() * Math.PI * 2;
        const phi = Math.acos((Math.random() * 2) - 1);

        positions[i * 3] = radius * Math.sin(phi) * Math.cos(theta);
        positions[i * 3 + 1] = radius * Math.sin(phi) * Math.sin(theta);
        positions[i * 3 + 2] = radius * Math.cos(phi);

        const r = Math.random();
        const c = r > 0.55 ? colorPink : (r > 0.25 ? colorGray : colorWhite);
        colors[i * 3] = c.r;
        colors[i * 3 + 1] = c.g;
        colors[i * 3 + 2] = c.b;
      }

      const pGeo = new THREE.BufferGeometry();
      pGeo.setAttribute('position', new THREE.BufferAttribute(positions, 3));
      pGeo.setAttribute('color', new THREE.BufferAttribute(colors, 3));

      const pMat = new THREE.PointsMaterial({
        size: 0.09,
        vertexColors: true,
        transparent: true,
        opacity: 0.85
      });

      particles = new THREE.Points(pGeo, pMat);
      scene.add(particles);

      return true;
    }

    if (!buildAuthScene()) return;

    function onPointerMove(e) {
      if (prefersReducedMotion) return;
      const clientX = e.clientX || (e.touches && e.touches[0] ? e.touches[0].clientX : window.innerWidth / 2);
      const clientY = e.clientY || (e.touches && e.touches[0] ? e.touches[0].clientY : window.innerHeight / 2);
      mouse.targetX = (clientX / window.innerWidth) * 2 - 1;
      mouse.targetY = -(clientY / window.innerHeight) * 2 + 1;
    }

    window.addEventListener('mousemove', onPointerMove, { passive: true });
    window.addEventListener('touchmove', onPointerMove, { passive: true });

    function onResize() {
      if (!renderer || !camera) return;
      const w = window.innerWidth;
      const h = window.innerHeight;
      camera.aspect = w / h;
      camera.updateProjectionMatrix();
      renderer.setSize(w, h);
    }
    window.addEventListener('resize', onResize);

    document.addEventListener('visibilitychange', () => {
      isVisible = (document.visibilityState === 'visible');
      if (isVisible && !animId) animate();
    });

    function animate() {
      if (!isVisible) {
        animId = null;
        return;
      }
      animId = requestAnimationFrame(animate);

      if (!prefersReducedMotion) {
        mouse.x += (mouse.targetX - mouse.x) * 0.04;
        mouse.y += (mouse.targetY - mouse.y) * 0.04;

        if (innerCore) {
          innerCore.rotation.y += 0.007;
          innerCore.rotation.x += 0.004;
        }
        if (outerWire) {
          outerWire.rotation.y -= 0.004;
          outerWire.rotation.z += 0.003;
        }
        orbitalRings.forEach((ring, idx) => {
          ring.rotation.z += (idx % 2 === 0 ? 0.005 : -0.005);
        });
        if (particles) {
          particles.rotation.y += 0.0015;
          particles.rotation.x = mouse.y * 0.12;
        }

        camera.position.x = mouse.x * 0.8;
        camera.position.y = mouse.y * 0.6;
        camera.lookAt(0, 0, 0);
      }

      renderer.render(scene, camera);
    }

    animate();
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initAuth3D);
  } else {
    initAuth3D();
  }
})();
