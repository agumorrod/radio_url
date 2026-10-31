/// Pasa a minúsculas y quita tildes: "Ágora" y "agora" cuentan como iguales.
/// Se usa en la búsqueda, en el orden por nombre y en la detección de iconos.
String normalizeText(String text) {
  const from = 'áàäâãéèëêíìïîóòöôõúùüûñç';
  const to = 'aaaaaeeeeiiiiooooouuuunc';
  var result = text.toLowerCase();
  for (var i = 0; i < from.length; i++) {
    result = result.replaceAll(from[i], to[i]);
  }
  return result;
}
