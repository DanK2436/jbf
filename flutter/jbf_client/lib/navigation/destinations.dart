class AppDestination {
  final int index;
  final String label;

  const AppDestination(this.index, this.label);
}

const clientDestinations = <AppDestination>[
  AppDestination(0, 'Tableau de bord'),
  AppDestination(1, 'Devis et commandes'),
  AppDestination(2, 'Chantiers'),
  AppDestination(3, 'Factures'),
  AppDestination(4, 'Avis'),
  AppDestination(5, 'Support'),
  AppDestination(6, 'Profil entreprise'),
];

const clientMobilePrimary = <int>[0, 1, 2, 3];
