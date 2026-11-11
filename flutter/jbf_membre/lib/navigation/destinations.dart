class AppDestination {
  final int index;
  final String label;

  const AppDestination(this.index, this.label);
}

const membreDestinations = <AppDestination>[
  AppDestination(0, 'Tableau de bord'),
  AppDestination(1, 'Missions'),
  AppDestination(2, 'Feuilles de temps'),
  AppDestination(3, 'Congés'),
  AppDestination(4, 'Messagerie'),
  AppDestination(5, 'Bibliothèque'),
];

const membreMobilePrimary = <int>[0, 1, 2, 3];
