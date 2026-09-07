import '../enums/circuit_phase_configuration.dart';
import '../enums/circuit_status.dart';
import '../enums/phase_assignment.dart';
import 'load_input.dart';
import 'panel_calculated_totals.dart';
import 'panel_electrical_system.dart';

class LoadScheduleExportHeader {
  const LoadScheduleExportHeader({
    required this.panelId,
    required this.panelNo,
    required this.electricalSystem,
    this.projectName,
    this.location,
  });

  final String panelId;
  final String panelNo;
  final PanelElectricalSystem electricalSystem;
  final String? projectName;
  final String? location;

  Map<String, Object?> toJson() => {
    'panelId': panelId,
    'panelNo': panelNo,
    'electricalSystem': electricalSystem.toJson(),
    if (projectName != null) 'projectName': projectName,
    if (location != null) 'location': location,
  };

  factory LoadScheduleExportHeader.fromJson(Map<String, Object?> json) =>
      LoadScheduleExportHeader(
        panelId: json['panelId'] as String,
        panelNo: json['panelNo'] as String,
        electricalSystem: PanelElectricalSystem.fromJson(
          Map<String, Object?>.from(json['electricalSystem'] as Map),
        ),
        projectName: json['projectName'] as String?,
        location: json['location'] as String?,
      );
}

class LoadScheduleExportRow {
  LoadScheduleExportRow({
    required this.circuitNo,
    required this.description,
    required this.status,
    required this.phaseConfiguration,
    this.assignedPhase,
    this.loadInput,
  }) {
    if (circuitNo <= 0) {
      throw ArgumentError.value(circuitNo, 'circuitNo');
    }
  }

  final int circuitNo;
  final String description;
  final CircuitStatus status;
  final CircuitPhaseConfiguration phaseConfiguration;
  final PhaseAssignment? assignedPhase;
  final LoadInput? loadInput;

  Map<String, Object?> toJson() => {
    'circuitNo': circuitNo,
    'description': description,
    'status': status.name,
    'phaseConfiguration': phaseConfiguration.name,
    if (assignedPhase != null) 'assignedPhase': assignedPhase!.name,
    if (loadInput != null) 'loadInput': loadInput!.toJson(),
  };

  factory LoadScheduleExportRow.fromJson(Map<String, Object?> json) =>
      LoadScheduleExportRow(
        circuitNo: json['circuitNo'] as int,
        description: json['description'] as String,
        status: CircuitStatus.values.byName(json['status'] as String),
        phaseConfiguration: CircuitPhaseConfiguration.values.byName(
          json['phaseConfiguration'] as String,
        ),
        assignedPhase: json['assignedPhase'] == null
            ? null
            : PhaseAssignment.values.byName(json['assignedPhase'] as String),
        loadInput: json['loadInput'] == null
            ? null
            : LoadInput.fromJson(
                Map<String, Object?>.from(json['loadInput'] as Map),
              ),
      );
}

class LoadScheduleExportSummary {
  const LoadScheduleExportSummary({required this.calculatedTotals});

  final PanelCalculatedTotals calculatedTotals;

  Map<String, Object?> toJson() => {
    'calculatedTotals': calculatedTotals.toJson(),
  };

  factory LoadScheduleExportSummary.fromJson(Map<String, Object?> json) =>
      LoadScheduleExportSummary(
        calculatedTotals: PanelCalculatedTotals.fromJson(
          Map<String, Object?>.from(json['calculatedTotals'] as Map),
        ),
      );
}

class LoadScheduleExportProjection {
  LoadScheduleExportProjection({
    required this.snapshotId,
    required this.header,
    required List<LoadScheduleExportRow> rows,
    required this.summary,
  }) : rows = List.unmodifiable(rows) {
    if (snapshotId.trim().isEmpty) {
      throw ArgumentError('An export projection requires a snapshot.');
    }
  }

  final String snapshotId;
  final LoadScheduleExportHeader header;
  final List<LoadScheduleExportRow> rows;
  final LoadScheduleExportSummary summary;

  Map<String, Object?> toJson() => {
    'snapshotId': snapshotId,
    'header': header.toJson(),
    'rows': rows.map((row) => row.toJson()).toList(),
    'summary': summary.toJson(),
  };

  factory LoadScheduleExportProjection.fromJson(Map<String, Object?> json) =>
      LoadScheduleExportProjection(
        snapshotId: json['snapshotId'] as String,
        header: LoadScheduleExportHeader.fromJson(
          Map<String, Object?>.from(json['header'] as Map),
        ),
        rows: (json['rows'] as List)
            .map(
              (row) => LoadScheduleExportRow.fromJson(
                Map<String, Object?>.from(row as Map),
              ),
            )
            .toList(),
        summary: LoadScheduleExportSummary.fromJson(
          Map<String, Object?>.from(json['summary'] as Map),
        ),
      );
}
