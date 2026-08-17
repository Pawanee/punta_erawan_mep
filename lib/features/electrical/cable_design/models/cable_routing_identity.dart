/// Typed cable identity for the production routing boundary.
///
/// It is deliberately separate from the active UI `CableType`, allowing a
/// future routing request to represent VAF/VAF-G without exposing them in the
/// current UI or changing legacy policy behaviour.
enum CableRoutingIdentity {
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

  const CableRoutingIdentity(this.code);
  final String code;
}
