/**
 * =============================================================
 * JBF Service — 3D INTERACTIVE WEBGL HERO EXPERIENCE
 * Scène 3D professionnelle temps réel (Three.js WebGL)
 * - Polyèdre cristallin minier (Symbole de la Copperbelt & RDC)
 * - Réseau de nœuds 3D interactifs (15 Pôles & 26 Provinces)
 * - Ondulation topographique industrielle
 * - Parallaxe réactive au mouvement de la souris et au gyroscope
 * =============================================================
 */

(function () {
  'use strict';

  // Vérification de la disponibilité de Three.js et du support WebGL
  if (typeof THREE === 'undefined') {
    console.warn('[JBF 3D] Three.js non détecté, repli vers rendu standard.');
    return;
  }

  const canvas = document.getElementById('hero3DCanvas');
  const heroSection = document.getElementById('hero');
  if (!canvas || !heroSection) return;

  // Détection des préférences utilisateur (mouvement réduit)
  const prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  // Variables de scène Three.js
  let renderer, scene, camera;
  let polyCore, wireCage, orbitRing1, orbitRing2, pointConstellation, terrainGrid;
  let mouse = { x: 0, y: 0, targetX: 0, targetY: 0 };
  let clock = new THREE.Clock();
  let isVisible = true;
  let animFrameId = null;

  // Initialisation de la scène
  function init3D() {
    const width = heroSection.clientWidth || window.innerWidth;
    const height = heroSection.clientHeight || window.innerHeight;

    // 1. Moteur de rendu WebGL haute performance
    try {
      renderer = new THREE.WebGLRenderer({
        canvas: canvas,
        alpha: true,
        antialias: true,
        powerPreference: 'high-performance'
      });
    } catch (e) {
      console.warn('[JBF 3D] Échec de création WebGLRenderer:', e);
      return;
    }

    renderer.setSize(width, height);
    renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2));
    renderer.setClearColor(0x000000, 0); // Transparent pour fusionner avec la DA

    // 2. Scène & Caméra perspective 3D
    scene = new THREE.Scene();
    camera = new THREE.PerspectiveCamera(52, width / height, 0.1, 1000);
    camera.position.set(0, 0, 38);

    // 3. Éclairages industriels sophistiqués
    const ambientLight = new THREE.AmbientLight(0xaaaaaa, 0.9); // 60% gris de base
    scene.add(ambientLight);

    // Spot lumineux rose vif (20% Rose logo #E6007E)
    const pinkKeyLight = new THREE.PointLight(0xE6007E, 2.8, 120);
    pinkKeyLight.position.set(18, 12, 22);
    scene.add(pinkKeyLight);

    // Lumière blanche contrastée (15% Blanc #FFFFFF)
    const whiteRimLight = new THREE.DirectionalLight(0xffffff, 1.2);
    whiteRimLight.position.set(-20, -15, 15);
    scene.add(whiteRimLight);

    // 4. Objet 3D Central : Polyèdre Cristallin Minier (Faceted Mining Gem)
    const coreGeo = new THREE.IcosahedronGeometry(7.2, 0);
    const coreMat = new THREE.MeshPhongMaterial({
      color: 0x18181c,
      emissive: 0x3d0022,
      specular: 0xE6007E,
      shininess: 90,
      flatShading: true,
      transparent: true,
      opacity: 0.92
    });
    polyCore = new THREE.Mesh(coreGeo, coreMat);
    polyCore.position.set(14, 1.5, 0); // Positionné avec élégance sur la droite
    scene.add(polyCore);

    // Cage filaire externe (Rose logo #E6007E)
    const wireGeo = new THREE.IcosahedronGeometry(8.1, 1);
    const wireMat = new THREE.MeshBasicMaterial({
      color: 0xE6007E,
      wireframe: true,
      transparent: true,
      opacity: 0.42
    });
    wireCage = new THREE.Mesh(wireGeo, wireMat);
    wireCage.position.copy(polyCore.position);
    scene.add(wireCage);

    // Anneaux orbitaux gyroscopiques (Symbolisant les flux logistiques & BTP)
    const ringGeo1 = new THREE.TorusGeometry(10.8, 0.08, 16, 100);
    const ringMat1 = new THREE.MeshBasicMaterial({ color: 0xE6007E, transparent: true, opacity: 0.55 });
    orbitRing1 = new THREE.Mesh(ringGeo1, ringMat1);
    orbitRing1.position.copy(polyCore.position);
    orbitRing1.rotation.x = Math.PI / 3;
    scene.add(orbitRing1);

    const ringGeo2 = new THREE.TorusGeometry(12.2, 0.06, 16, 100);
    const ringMat2 = new THREE.MeshBasicMaterial({ color: 0xaaaaaa, transparent: true, opacity: 0.45 });
    orbitRing2 = new THREE.Mesh(ringGeo2, ringMat2);
    orbitRing2.position.copy(polyCore.position);
    orbitRing2.rotation.y = Math.PI / 4;
    scene.add(orbitRing2);

    // 5. Nuage de Particules 3D (Constellation interactive - 450 nœuds)
    const particleCount = 420;
    const particleGeo = new THREE.BufferGeometry();
    const positions = new Float32Array(particleCount * 3);
    const colors = new Float32Array(particleCount * 3);

    const colorPink = new THREE.Color(0xE6007E);
    const colorGray = new THREE.Color(0xaaaaaa);
    const colorWhite = new THREE.Color(0xffffff);

    for (let i = 0; i < particleCount; i++) {
      const i3 = i * 3;
      positions[i3] = (Math.random() - 0.5) * 85;
      positions[i3 + 1] = (Math.random() - 0.5) * 55;
      positions[i3 + 2] = (Math.random() - 0.5) * 50;

      // Distribution chromatique harmonisée (60% gris, 20% rose, 15% blanc)
      const r = Math.random();
      let chosenColor = colorGray;
      if (r < 0.22) {
        chosenColor = colorPink;
      } else if (r < 0.38) {
        chosenColor = colorWhite;
      }
      colors[i3] = chosenColor.r;
      colors[i3 + 1] = chosenColor.g;
      colors[i3 + 2] = chosenColor.b;
    }

    particleGeo.setAttribute('position', new THREE.BufferAttribute(positions, 3));
    particleGeo.setAttribute('color', new THREE.BufferAttribute(colors, 3));

    const particleMat = new THREE.PointsMaterial({
      size: 0.65,
      vertexColors: true,
      transparent: true,
      opacity: 0.85
    });
    pointConstellation = new THREE.Points(particleGeo, particleMat);
    scene.add(pointConstellation);

    // 6. Matrice topographique ondulante en arrière-plan (Génie Civil & Topographie minière)
    const terrainGeo = new THREE.PlaneGeometry(90, 60, 24, 18);
    const terrainMat = new THREE.MeshBasicMaterial({
      color: 0x888890,
      wireframe: true,
      transparent: true,
      opacity: 0.16
    });
    terrainGrid = new THREE.Mesh(terrainGeo, terrainMat);
    terrainGrid.position.set(0, -18, -12);
    terrainGrid.rotation.x = -Math.PI / 2.3;
    scene.add(terrainGrid);

    // Écouteurs d'événements
    setupEventListeners();

    // Démarrage de la boucle de rendu
    animate();
  }

  // Gestion des interactions curseur et redimensionnement
  function setupEventListeners() {
    window.addEventListener('resize', onWindowResize, { passive: true });

    // Tracking souris fluide avec normalisation [-1, 1]
    window.addEventListener('mousemove', (e) => {
      mouse.targetX = (e.clientX / window.innerWidth) * 2 - 1;
      mouse.targetY = -(e.clientY / window.innerHeight) * 2 + 1;
    }, { passive: true });

    // Prise en charge de l'orientation mobile (Gyroscope)
    if (window.DeviceOrientationEvent) {
      window.addEventListener('deviceorientation', (e) => {
        if (e.gamma !== null && e.beta !== null) {
          mouse.targetX = Math.min(Math.max(e.gamma / 35, -1), 1);
          mouse.targetY = Math.min(Math.max((e.beta - 45) / 35, -1), 1);
        }
      }, { passive: true });
    }

    // Optimisation : mettre en pause le rendu quand le hero n'est plus visible
    if ('IntersectionObserver' in window) {
      const heroObserver = new IntersectionObserver((entries) => {
        entries.forEach((entry) => {
          isVisible = entry.isIntersecting;
        });
      }, { threshold: 0.05 });
      heroObserver.observe(heroSection);
    }
  }

  function onWindowResize() {
    if (!renderer || !camera || !heroSection) return;
    const width = heroSection.clientWidth || window.innerWidth;
    const height = heroSection.clientHeight || window.innerHeight;

    camera.aspect = width / height;

    // Ajustement de la position de la gemme 3D selon l'écran (mobile vs desktop)
    if (width < 900) {
      polyCore.position.set(0, 4, -8);
      wireCage.position.copy(polyCore.position);
      orbitRing1.position.copy(polyCore.position);
      orbitRing2.position.copy(polyCore.position);
    } else {
      polyCore.position.set(13.5, 1.2, 0);
      wireCage.position.copy(polyCore.position);
      orbitRing1.position.copy(polyCore.position);
      orbitRing2.position.copy(polyCore.position);
    }

    camera.updateProjectionMatrix();
    renderer.setSize(width, height);
  }

  // Boucle d'animation 60 FPS
  function animate() {
    animFrameId = requestAnimationFrame(animate);

    if (!isVisible) return; // Économie de batterie & processeur

    const elapsedTime = clock.getElapsedTime();
    const speedFactor = prefersReducedMotion ? 0.25 : 1.0;

    // Amortissement fluide de la souris (Interpolation Lerp)
    mouse.x += (mouse.targetX - mouse.x) * 0.05;
    mouse.y += (mouse.targetY - mouse.y) * 0.05;

    // Mouvement orbital et rotation des maillages 3D
    if (polyCore) {
      polyCore.rotation.x = elapsedTime * 0.28 * speedFactor;
      polyCore.rotation.y = elapsedTime * 0.35 * speedFactor;
      polyCore.position.y += Math.sin(elapsedTime * 1.4) * 0.012; // Lévitation douce
    }
    if (wireCage) {
      wireCage.rotation.x = -elapsedTime * 0.2 * speedFactor;
      wireCage.rotation.y = -elapsedTime * 0.25 * speedFactor;
      wireCage.position.copy(polyCore.position);
    }
    if (orbitRing1) {
      orbitRing1.rotation.z = elapsedTime * 0.45 * speedFactor;
      orbitRing1.rotation.x = Math.PI / 3 + mouse.y * 0.3;
    }
    if (orbitRing2) {
      orbitRing2.rotation.z = -elapsedTime * 0.38 * speedFactor;
      orbitRing2.rotation.y = Math.PI / 4 + mouse.x * 0.3;
    }

    // Ondulation dynamique du nuage de particules
    if (pointConstellation) {
      pointConstellation.rotation.y = elapsedTime * 0.04 * speedFactor;
      pointConstellation.rotation.x = mouse.y * 0.08;
    }

    // Déplacement de la caméra 3D avec parallaxe interactive
    camera.position.x += (mouse.x * 4.5 - camera.position.x) * 0.04;
    camera.position.y += (mouse.y * 3.5 - camera.position.y) * 0.04;
    camera.lookAt(0, 0, 0);

    renderer.render(scene, camera);
  }

  // Initialisation dès que le DOM est prêt
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init3D);
  } else {
    init3D();
  }
})();
