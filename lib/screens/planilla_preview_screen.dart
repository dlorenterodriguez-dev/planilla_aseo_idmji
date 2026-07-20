import 'package:flutter/material.dart';
import '../models/volunteer.dart';
import '../services/volunteer_storage_service.dart';
import '../services/assignment_storage_service.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/rendering.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../services/week_service.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';

class PlanillaPreviewScreen extends StatefulWidget {
  const PlanillaPreviewScreen({super.key});

  @override
  State<PlanillaPreviewScreen> createState() =>
      _PlanillaPreviewScreenState();
}

class _PlanillaPreviewScreenState
    extends State<PlanillaPreviewScreen> {
      final GlobalKey planillaKey = GlobalKey();
      Map<String, String> volunteerMap = {};
      DateTime? weekStart;
      DateTime get martes => weekStart!.add(const Duration(days: 1));
      DateTime get sabado => weekStart!.add(const Duration(days: 5));
      DateTime get domingo => weekStart!.add(const Duration(days: 6));

  String volunteerName(String id) {
    return volunteerMap[id] ?? id;
  }

  List<String> alabanzaIds = [];
  List<String> estudioIds = [];
  List<String> ensenanzaIds = [];

  Future<void> _loadData() async {
    final loadedWeekStart = await WeekService.loadWeekStart();
    final List<Volunteer> volunteers =
    await VolunteerStorageService.loadVolunteers();

    final alabanza = await AssignmentStorageService.loadAssignmentIds(
      'alabanza_assignments_v2',
    );

    final estudio = await AssignmentStorageService.loadAssignmentIds(
      'estudio_assignments_v2',
    );

    final ensenanza = await AssignmentStorageService.loadAssignmentIds(
      'ensenanza_assignments_v2',
    );

    setState(() {
      weekStart = loadedWeekStart;

      volunteerMap = {
        for (final volunteer in volunteers)
          volunteer.id: volunteer.name,
      };
      alabanzaIds = alabanza;
      estudioIds = estudio;
      ensenanzaIds = ensenanza;
    });
  }

      Future<void> capturarPlanilla() async {
        final boundary =
        planillaKey.currentContext!.findRenderObject()
        as RenderRepaintBoundary;

        final image = await boundary.toImage(pixelRatio: 3);

        final byteData = await image.toByteData(
          format: ui.ImageByteFormat.png,
        );

        final Uint8List pngBytes =
        byteData!.buffer.asUint8List();

        final directory =
        await getTemporaryDirectory();

        final nombreArchivo = weekStart == null
            ? 'planilla.png'
            : 'planilla_${DateFormat('yyyy-MM-dd').format(weekStart!)}.png';

        final file = File(
          '${directory.path}/$nombreArchivo',
        );

        await file.writeAsBytes(pngBytes);

        await Share.shareXFiles(
          [
            XFile(file.path),
          ],
          text: 'Planilla de Vigilancia y Acomodación',
        );
      }

  @override
  void initState() {
    super.initState();
    _loadData();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compartir planilla'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: capturarPlanilla,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: RepaintBoundary(
            key: planillaKey,
            child: Container(            width: 350,
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                SvgPicture.asset(
                  'assets/images/logo_idmji.svg',
                  height:80,
                ),
                SizedBox(height: 8),
                Text(
                  'Vigilancia y Acomodación',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),

                SizedBox(height: 8),

                Text(
                  weekStart == null
                      ? ''
                      : '${weekStart!.day} al '
                      '${weekStart!.add(const Duration(days: 6)).day} de '
                      '${DateFormat.MMMM('es_ES').format(weekStart!)}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                SizedBox(height: 24),

                _ServiceBlock(
                  title: weekStart == null
                      ? ''
                      : 'Martes ${martes.day}',
                  subtitle: 'ALABANZA',
                  noHayCulto: alabanzaIds.every((id) => id.isEmpty),
                  rows: [
                    [
                      'Vigilancia (18 a 19h):',
                      alabanzaIds.isNotEmpty
                          ? volunteerName(alabanzaIds[0])
                          : '',
                    ],
                    [
                      'Vigilancia (19 a 19:45h):',
                      alabanzaIds.length > 1
                          ? volunteerName(alabanzaIds[1])
                          : '',
                    ],
                    [
                      'Vigilancia (19:45 a 20:30):',
                      alabanzaIds.length > 2
                          ? volunteerName(alabanzaIds[2])
                          : '',
                    ],
                  ],
                ),

                SizedBox(height: 24),

                _ServiceBlock(
                  title: weekStart == null
                      ? ''
                      : 'Sábado ${sabado.day}',
                  subtitle: 'ESTUDIO',
                  noHayCulto: estudioIds.every((id) => id.isEmpty),
                  rows: [
                    [
                      'Vigilancia (16 a 17h):',
                      estudioIds.isNotEmpty
                          ? volunteerName(estudioIds[0])
                          : '',
                    ],
                    [
                      'Vigilancia (17 a 17:45h):',
                      estudioIds.length > 1
                          ? volunteerName(estudioIds[1])
                          : '',
                    ],
                    [
                      'Vigilancia (17:45 a 18:30):',
                      estudioIds.length > 2
                          ? volunteerName(estudioIds[2])
                          : '',
                    ],
                  ],
                ),
                const SizedBox(height: 24),

                _ServiceBlock(
                  title: weekStart == null
                      ? ''
                      : 'Domingo ${domingo.day}',
                  subtitle: 'ENSEÑANZA',
                  noHayCulto: ensenanzaIds.every((id) => id.isEmpty),
                  rows: [
                    [
                      'Vigilancia (16 a 17h):',
                      ensenanzaIds.isNotEmpty
                          ? volunteerName(ensenanzaIds[0])
                          : '',
                    ],
                    [
                      'Vigilancia (17 a 17:45h):',
                      ensenanzaIds.length > 1
                          ? volunteerName(ensenanzaIds[1])
                          : '',
                    ],
                    [
                      'Vigilancia (17:45 a 18:30):',
                      ensenanzaIds.length > 2
                          ? volunteerName(ensenanzaIds[2])
                          : '',
                    ],
                    [
                      'Micrófono:',
                      ensenanzaIds.length > 3
                          ? volunteerName(ensenanzaIds[3])
                          : '',
                    ],
                    [
                      'Acomodación 1 (17:00 a 17:30):',
                      ensenanzaIds.length > 4
                          ? volunteerName(ensenanzaIds[4])
                          : '',
                    ],
                    [
                      'Acomodación 2 (17:00 a 17:30):',
                      ensenanzaIds.length > 5
                          ? volunteerName(ensenanzaIds[5])
                          : '',
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }
}

class _ServiceBlock extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<List<String>> rows;
  final bool noHayCulto;

  const _ServiceBlock({
    required this.title,
    required this.subtitle,
    required this.rows,
    this.noHayCulto = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.blue,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          subtitle,
          style: const TextStyle(
            color: Colors.blue,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),

        // Línea dorada siempre visible
        Container(
          height: 3,
          color: const Color(0xFFD4AF37),
        ),

        if (noHayCulto)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'No hay culto',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          )
        else
          ...List.generate(rows.length, (index) {
            final row = rows[index];

            return Container(
              color: index.isOdd
                  ? const Color(0xFFEAF4FF) // azul muy suave
                  : Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(row[0]),
                  ),
                  Text(
                    row[1],
                    textAlign: TextAlign.right,
                  ),
                ],
              ),
            );
          }),
        const SizedBox(height: 24),
      ],
    );
  }
}