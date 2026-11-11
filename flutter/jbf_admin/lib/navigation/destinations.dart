class AppDestination {
  final int index;
  final String label;

  const AppDestination(this.index, this.label);
}

const adminDestinations = <AppDestination>[
  AppDestination(0, 'Tableau de bord'),
  AppDestination(1, 'Devis et commandes'),
  AppDestination(2, 'Missions et chantiers'),
  AppDestination(3, 'Pointages'),
  AppDestination(4, 'Congés'),
  AppDestination(5, 'Avis'),
  AppDestination(6, 'Membres'),
  AppDestination(7, 'Sous-administrateurs'),
  AppDestination(8, 'Sécurité OTP'),
];

const adminMobilePrimary = <int>[0, 1, 2, 3];
