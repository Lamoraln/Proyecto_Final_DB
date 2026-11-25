export function clasificar({ existencia, minimo }) {
  if (existencia === null) return 'ausente';
  if (existencia === 0) return 'agotado';
  if (existencia < minimo) return 'bajo';
  return 'disponible';
}