class FilterOption<T> {
  final String label;
  final T value;

  const FilterOption({
    required this.label,
    required this.value,
  });
}

// Protections
final List<FilterOption<String>> protectionStatusOptions = [
  FilterOption(label: "Protection départementale", value: "PD"),
  FilterOption(label: "Protection nationale", value: "PN"),
  FilterOption(label: "Protection régionale", value: "PR"),
];

// Réglementations
final List<FilterOption<String>> regulationStatusOptions = [
  FilterOption(label: "Interdiction d'introduction", value: "REGLII"),
  FilterOption(label: "Lutte contre certaines espèces", value: "REGLLUTTE"),
  FilterOption(label: "Réglementation", value: "REGL"),
  FilterOption(label: "Réglementation sans objet", value: "REGLSO"),
];

// Liste rouge mondiale
final List<FilterOption<String>> worldwideRedListOptions = [
  FilterOption(label: "EX - Éteinte", value: "EX"),
  FilterOption(label: "EW - Éteinte à l'état sauvage", value: "EW"),
  FilterOption(label: "CR - En danger critique", value: "CR"),
  FilterOption(label: "EN - En danger", value: "EN"),
  FilterOption(label: "VU - Vulnérable", value: "VU"),
  FilterOption(label: "NT - Quasi menacée", value: "NT"),
  FilterOption(label: "LC - Préoccupation mineure", value: "LC"),
  FilterOption(label: "DD - Données insuffisantes", value: "DD"),
];

// Liste rouge européenne
final List<FilterOption<String>> europeanRedListOptions = [
  FilterOption(label: "EX - Éteinte", value: "EX"),
  FilterOption(label: "CR - En danger critique", value: "CR"),
  FilterOption(label: "EN - En danger", value: "EN"),
  FilterOption(label: "VU - Vulnérable", value: "VU"),
  FilterOption(label: "NT - Quasi menacée", value: "NT"),
  FilterOption(label: "LC - Préoccupation mineure", value: "LC"),
  FilterOption(label: "DD - Données insuffisantes", value: "DD"),
];

// Liste rouge nationale
final List<FilterOption<String>> nationalRedListOptions = [
  FilterOption(label: "EX - Éteinte au niveau mondial", value: "EX"),
  FilterOption(label: "RE - Disparue au niveau régional", value: "RE"),
  FilterOption(label: "CR - En danger critique", value: "CR"),
  FilterOption(label: "CR* - Éteinte ou disparue ?", value: "CR*"),
  FilterOption(label: "EN - En danger", value: "EN"),
  FilterOption(label: "VU - Vulnérable", value: "VU"),
  FilterOption(label: "NT - Quasi menacée", value: "NT"),
  FilterOption(label: "LC - Préoccupation mineure", value: "LC"),
  FilterOption(label: "DD - Données insuffisantes", value: "DD"),
  FilterOption(label: "NA - Non applicable", value: "NA"),
  FilterOption(label: "NE - Non évaluée", value: "NE"),
];

// Liste rouge régionale
final List<FilterOption<String>> regionalRedListOptions = [
  FilterOption(label: "EX - Éteinte au niveau mondial", value: "EX"),
  FilterOption(label: "EW - Éteinte à l'état sauvage", value: "EW"),
  FilterOption(label: "RE - Disparue au niveau régional", value: "RE"),
  FilterOption(label: "RE? - Disparue au niveau régional ?", value: "RE?"),
  FilterOption(label: "CR - En danger critique", value: "CR"),
  FilterOption(label: "CR* - Éteinte ou disparue ?", value: "CR*"),
  FilterOption(label: "EN - En danger", value: "EN"),
  FilterOption(label: "VU - Vulnérable", value: "VU"),
  FilterOption(label: "NT - Quasi menacée", value: "NT"),
  FilterOption(label: "LC - Préoccupation mineure", value: "LC"),
  FilterOption(label: "DD - Données insuffisantes", value: "DD"),
  FilterOption(label: "NA - Non applicable", value: "NA"),
  FilterOption(label: "NE - Non évaluée", value: "NE"),
];

// Habitat
final List<FilterOption<String>> habitatOptions = [
  FilterOption(label: "Marin", value: "1"),
  FilterOption(label: "Eau douce", value: "2"),
  FilterOption(label: "Terrestre", value: "3"),
  FilterOption(label: "Marin et eau douce", value: "4"),
  FilterOption(label: "Marin et terrestre", value: "5"),
  FilterOption(label: "Eau saumâtre", value: "6"),
  FilterOption(label: "Continental (terrestre et/ou eau douce)", value: "7"),
  FilterOption(label: "Continental (terrestre et eau douce)", value: "8"),
];

// Groupe 2
final List<FilterOption<String>> group2Options = [
  FilterOption(label: "Acanthocéphales", value: "Acanthocéphales"),
  FilterOption(label: "Amphibiens", value: "Amphibiens"),
  FilterOption(label: "Annélides", value: "Annélides"),
  FilterOption(label: "Arachnides", value: "Arachnides"),
  FilterOption(label: "Ascidies", value: "Ascidies"),
  FilterOption(label: "Autres", value: "Autres"),
  FilterOption(label: "Bivalves", value: "Bivalves"),
  FilterOption(label: "Crustacés", value: "Crustacés"),
  FilterOption(label: "Céphalopodes", value: "Céphalopodes"),
  FilterOption(label: "Entognathes", value: "Entognathes"),
  FilterOption(label: "Gastéropodes", value: "Gastéropodes"),
  FilterOption(label: "Hydrozoaires", value: "Hydrozoaires"),
  FilterOption(label: "Insectes", value: "Insectes"),
  FilterOption(label: "Mammifères", value: "Mammifères"),
  FilterOption(label: "Myriapodes", value: "Myriapodes"),
  FilterOption(label: "Nématodes", value: "Nématodes"),
  FilterOption(label: "Némertes", value: "Némertes"),
  FilterOption(label: "Octocoralliaires", value: "Octocoralliaires"),
  FilterOption(label: "Oiseaux", value: "Oiseaux"),
  FilterOption(label: "Plathelminthes", value: "Plathelminthes"),
  FilterOption(label: "Poissons", value: "Poissons"),
  FilterOption(label: "Pycnogonides", value: "Pycnogonides"),
  FilterOption(label: "Reptiles", value: "Reptiles"),
  FilterOption(label: "Scléractiniaires", value: "Scléractiniaires"),
  FilterOption(label: "Diatomées", value: "Diatomées"),
  FilterOption(label: "Ochrophytes", value: "Ochrophytes"),
  FilterOption(label: "Lichens", value: "Lichens"),
  FilterOption(label: "Angiospermes", value: "Angiospermes"),
  FilterOption(label: "Chlorophytes et Charophytes", value: "Chlorophytes et Charophytes"),
  FilterOption(label: "Gymnospermes", value: "Gymnospermes"),
  FilterOption(label: "Hépatiques et Anthocérotes", value: "Hépatiques et Anthocérotes"),
  FilterOption(label: "Mousses", value: "Mousses"),
  FilterOption(label: "Ptéridophytes", value: "Ptéridophytes"),
  FilterOption(label: "Rhodophytes", value: "Rhodophytes"),
];

// Groupe 3
final List<FilterOption<String>> group3Options = [
  FilterOption(label: "Acariens", value: "Acariens"),
  FilterOption(label: "Amphipodes", value: "Amphipodes"),
  FilterOption(label: "Araignées", value: "Araignées"),
  FilterOption(label: "Autres", value: "Autres"),
  FilterOption(label: "Branchiopodes", value: "Branchiopodes"),
  FilterOption(label: "Branchiures", value: "Branchiures"),
  FilterOption(label: "Chilopodes", value: "Chilopodes"),
  FilterOption(label: "Coléoptères", value: "Coléoptères"),
  FilterOption(label: "Copépodes", value: "Copépodes"),
  FilterOption(label: "Diplopodes", value: "Diplopodes"),
  FilterOption(label: "Diptères", value: "Diptères"),
  FilterOption(label: "Décapodes", value: "Décapodes"),
  FilterOption(label: "Hyménoptères", value: "Hyménoptères"),
  FilterOption(label: "Hémiptères", value: "Hémiptères"),
  FilterOption(label: "Isopodes", value: "Isopodes"),
  FilterOption(label: "Lépidoptères", value: "Lépidoptères"),
  FilterOption(label: "Odonates", value: "Odonates"),
  FilterOption(label: "Opilions", value: "Opilions"),
  FilterOption(label: "Orthoptères", value: "Orthoptères"),
  FilterOption(label: "Ostracodes", value: "Ostracodes"),
  FilterOption(label: "Pauropodes", value: "Pauropodes"),
  FilterOption(label: "Pseudoscorpions", value: "Pseudoscorpions"),
  FilterOption(label: "Scorpions", value: "Scorpions"),
  FilterOption(label: "Symphyles", value: "Symphyles"),
];