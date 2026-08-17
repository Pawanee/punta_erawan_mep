/// Cable types covered by approved cable-profile source facts.
///
/// This is separate from the active UI CableType enum so VAF/VAF-G profiles do
/// not become selectable in the current cable-design UI.
enum CableProfileType {
  iec01('60227 IEC 01'),
  iec02('60227 IEC 02'),
  iec05('60227 IEC 05'),
  iec06('60227 IEC 06'),
  iec10('60227 IEC 10'),
  nyy('NYY'),
  nyyG('NYY-G'),
  vaf('VAF'),
  vafG('VAF-G'),
  vct('VCT'),
  vctG('VCT-G'),
  iec605021('IEC 60502-1');

  const CableProfileType(this.code);
  final String code;
}
