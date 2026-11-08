/**
 * =============================================================
 * JBF Client — 3D LUXURY KINETIC SCULPTURE BANNER
 * Moteur WebGL Three.js ultra-haute fidélité pour le portail client
 * - Noyau géométrique facetté haute précision (Rose Logo #E6007E)
 * - Cage cristalline polyédrique extérieure à facettes multiples
 * - Double anneau orbital gyroscopique en Titane Gris (#AAAAAA) et Rose Chrome
 * - Constellation de 15 nœuds satellites orbitaux (Représentant les 15 Métiers JBF)
 * - Nuage de particules de données industrielles avec lueurs dynamiques
 * - Interaction physique réactive au survol et aux mouvements de la souris
 * =============================================================
 */

(function () {
  'use strict';

  function initClient3DBanner() {
    if (typeof THREE === 'undefined') return;

    const canvas = document.getElementById('clientBanner3DCanvas');
    const container = document.getElementById('clientHeroMotionCard');
    if (!canvas || !container) return;

    const prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

    let renderer, scene, camera;
    let coreMesh, cageMesh, nucleusMesh, ring1, ring2, satellitesGroup, particles;
    let mouse = { x: 0, y: 0, targetX: 0, targetY: 0 };
    let isHovered = false;
    let rotationSpeed = 1.0;
    let isVisible = true;
    let animId = null;

    function buildScene() {
      const width = container.clientWidth || 800;
      const height = container.clientHeight || 240;

      try {
        renderer = new THREE.WebGLRenderer({
          canvas: canvas,
          alpha: true,
          antialias: true,
          powerPreference: 'high-performance'
        });
      } catch (e) {
        console.warn('[JBF Client 3D] WebGL non disponible:', e);
        return false;
      }

      renderer.setSize(width, height);
      renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2));
      renderer.setClearColor(0x000000, 0);

      scene = new THREE.Scene();
      camera = new THREE.PerspectiveCamera(42, width / height, 0.1, 100);
      camera.position.set(0, 0, 8.2);

      // Système d'éclairage de précision
      const ambientLight = new THREE.AmbientLight(0xffffff, 0.9);
      scene.add(ambientLight);

      const pinkLight = new THREE.PointLight(0xE6007E, 3.2, 25);
      pinkLight.position.set(4, 3, 5);
      scene.add(pinkLight);

      const silverLight = new THREE.PointLight(0xAAAAAA, 2.0, 25);
      silverLight.position.set(-5, -3, 4);
      scene.add(silverLight);

      const topLight = new THREE.DirectionalLight(0xFFFFFF, 0.6);
      topLight.position.set(0, 6, 4);
      scene.add(topLight);

      // 1. Cœur cristallin facetté (Rose Logo vibrant)
      const coreGeo = new THREE.IcosahedronGeometry(1.35, 0);
      const coreMat = new THREE.MeshStandardMaterial({
        color: 0xE6007E,
        metalness: 0.85,
        roughness: 0.18,
        flatShading: true
      });
      coreMesh = new THREE.Mesh(coreGeo, coreMat);
      scene.add(coreMesh);

      // 2. Noyau interne lumineux (Énergie centrale)
      const nucleusGeo = new THREE.OctahedronGeometry(0.7, 0);
      const nucleusMat = new THREE.MeshBasicMaterial({
        color: 0xFF1A8C,
        wireframe: true,
        transparent: true,
        opacity: 0.75
      });
      nucleusMesh = new THREE.Mesh(nucleusGeo, nucleusMat);
      scene.add(nucleusMesh);

      // 3. Cage filaire externe (Titane Chrome & Reflets)
      const cageGeo = new THREE.DodecahedronGeometry(2.1, 0);
      const cageMat = new THREE.MeshBasicMaterial({
        color: 0xF472B6,
        wireframe: true,
        transparent: true,
        opacity: 0.4
      });
      cageMesh = new THREE.Mesh(cageGeo, cageMat);
      scene.add(cageMesh);

      // 4. Anneau orbital 1 (Titane Gris #AAAAAA)
      const ringGeo1 = new THREE.TorusGeometry(2.7, 0.035, 16, 90);
      const ringMat1 = new THREE.MeshBasicMaterial({
        color: 0xAAAAAA,
        transparent: true,
        opacity: 0.75
      });
      ring1 = new THREE.Mesh(ringGeo1, ringMat1);
      ring1.rotation.x = Math.PI / 3;
      scene.add(ring1);

      // 5. Anneau orbital 2 (Rose Logo #E6007E)
      const ringGeo2 = new THREE.TorusGeometry(3.15, 0.025, 16, 90);
      const ringMat2 = new THREE.MeshBasicMaterial({
        color: 0xE6007E,
        transparent: true,
        opacity: 0.6
      });
      ring2 = new THREE.Mesh(ringGeo2, ringMat2);
      ring2.rotation.y = Math.PI / 4;
      scene.add(ring2);

      // 6. Groupe de 15 nœuds satellites (Les 15 Pôles JBF)
      satellitesGroup = new THREE.Group();
      const satGeo = new THREE.BoxGeometry(0.12, 0.12, 0.12);
      const satMatPink = new THREE.MeshStandardMaterial({ color: 0xE6007E, metalness: 0.9, roughness: 0.1 });
      const satMatSilver = new THREE.MeshStandardMaterial({ color: 0xCCCCCC, metalness: 0.9, roughness: 0.1 });

      for (let i = 0; i < 15; i++) {
        const satMesh = new THREE.Mesh(satGeo, (i % 2 === 0) ? satMatPink : satMatSilver);
        const angle = (i / 15) * Math.PI * 2;
        const dist = 2.7;
        satMesh.position.set(Math.cos(angle) * dist, (Math.sin(angle * 2) * 0.4), Math.sin(angle) * dist);
        satellitesGroup.add(satMesh);
      }
      satellitesGroup.rotation.x = Math.PI / 3;
      scene.add(satellitesGroup);

      // 7. Nuage de particules de données industrielles
      const particleCount = 150;
      const positions = new Float32Array(particleCount * 3);
      const colors = new Float32Array(particleCount * 3);
      const colorPink = new THREE.Color(0xE6007E);
      const colorGray = new THREE.Color(0xAAAAAA);
      const colorWhite = new THREE.Color(0xFFFFFF);

      for (let i = 0; i < particleCount; i++) {
        const radius = 2.4 + Math.random() * 4.2;
        const theta = Math.random() * Math.PI * 2;
        const phi = Math.acos((Math.random() * 2) - 1);

        positions[i * 3] = radius * Math.sin(phi) * Math.cos(theta);
        positions[i * 3 + 1] = radius * Math.sin(phi) * Math.sin(theta);
        positions[i * 3 + 2] = radius * Math.cos(phi);

        const pick = Math.random();
        const c = pick > 0.55 ? colorPink : (pick > 0.25 ? colorGray : colorWhite);
        colors[i * 3] = c.r;
        colors[i * 3 + 1] = c.g;
        colors[i * 3 + 2] = c.b;
      }

      const particleGeo = new THREE.BufferGeometry();
      particleGeo.setAttribute('position', new THREE.BufferAttribute(positions, 3));
      particleGeo.setAttribute('color', new THREE.BufferAttribute(colors, 3));

      const particleMat = new THREE.PointsMaterial({
        size: 0.085,
        vertexColors: true,
        transparent: true,
        opacity: 0.85
      });

      particles = new THREE.Points(particleGeo, particleMat);
      scene.add(particles);

      return true;
    }

    if (!buildScene()) return;

    // Événements d'interaction
    function onPointerMove(e) {
      if (prefersReducedMotion) return;
      const rect = container.getBoundingClientRect();
      const clientX = e.clientX || (e.touches && e.touches[0] ? e.touches[0].clientX : 0);
      const clientY = e.clientY || (e.touches && e.touches[0] ? e.touches[0].clientY : 0);
      mouse.targetX = ((clientX - rect.left) / rect.width) * 2 - 1;
      mouse.targetY = -(((clientY - rect.top) / rect.height) * 2 - 1);
    }

    container.addEventListener('mousemove', onPointerMove, { passive: true });
    container.addEventListener('touchmove', onPointerMove, { passive: true });

    container.addEventListener('mouseenter', () => {
      isHovered = true;
    });

    container.addEventListener('mouseleave', () => {
      isHovered = false;
      mouse.targetX = 0;
      mouse.targetY = 0;
    });

    function onResize() {
      if (!renderer || !camera || !container) return;
      const w = container.clientWidth || 800;
      const h = container.clientHeight || 240;
      camera.aspect = w / h;
      camera.updateProjectionMatrix();
      renderer.setSize(w, h);
    }
    window.addEventListener('resize', onResize);

    if ('IntersectionObserver' in window) {
      const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
          isVisible = entry.isIntersecting;
          if (isVisible && !animId) animate();
        });
      }, { threshold: 0.1 });
      observer.observe(container);
    }

    // Boucle d'animation
    function animate() {
      if (!isVisible) {
        animId = null;
        return;
      }

      animId = requestAnimationFrame(animate);

      if (!prefersReducedMotion) {
        // Accélération fluide au survol
        const targetSpeed = isHovered ? 1.6 : 1.0;
        rotationSpeed += (targetSpeed - rotationSpeed) * 0.05;

        // Inertie souris
        mouse.x += (mouse.targetX - mouse.x) * 0.05;
        mouse.y += (mouse.targetY - mouse.y) * 0.05;

        // Rotations cinétiques
        if (coreMesh) {
          coreMesh.rotation.y += 0.008 * rotationSpeed;
          coreMesh.rotation.x += 0.005 * rotationSpeed;
        }
        if (nucleusMesh) {
          nucleusMesh.rotation.y -= 0.012 * rotationSpeed;
          nucleusMesh.rotation.z += 0.008 * rotationSpeed;
        }
        if (cageMesh) {
          cageMesh.rotation.y -= 0.005 * rotationSpeed;
          cageMesh.rotation.z += 0.004 * rotationSpeed;
        }
        if (ring1) {
          ring1.rotation.z += 0.007 * rotationSpeed;
          ring1.rotation.x = Math.PI / 3 + mouse.y * 0.35;
        }
        if (ring2) {
          ring2.rotation.z -= 0.006 * rotationSpeed;
          ring2.rotation.y = Math.PI / 4 + mouse.x * 0.35;
        }
        if (satellitesGroup) {
          satellitesGroup.rotation.z += 0.007 * rotationSpeed;
        }
        if (particles) {
          particles.rotation.y += 0.002 * rotationSpeed;
          particles.rotation.x = mouse.y * 0.15;
        }

        // Parallaxe caméra
        camera.position.x = mouse.x * 0.75;
        camera.position.y = mouse.y * 0.55;
        camera.lookAt(0, 0, 0);
      }

      renderer.render(scene, camera);
    }

    animate();
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initClient3DBanner);
  } else {
    initClient3DBanner();
  }
})();
