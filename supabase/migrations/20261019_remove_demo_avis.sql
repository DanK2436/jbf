-- Supprime les témoignages de démonstration éventuellement insérés en base.
-- Exécuter dans Supabase → SQL Editor si des avis fictifs apparaissent encore côté admin.

DELETE FROM public.avis_clients
WHERE approuve = true
  AND (
    nom ILIKE '%Direction Logistique%'
    OR nom ILIKE '%Responsable Approvisionnement%'
    OR nom ILIKE '%Chef de Projet BTP%'
    OR commentaire ILIKE '%Intervention exemplaire pour la gestion de nos équipes%'
    OR commentaire ILIKE '%Qualité alimentaire et traçabilité HACCP%'
    OR commentaire ILIKE '%Travaux de coffrage et de bétonnage%'
  );
