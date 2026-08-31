import 'package:flutter/material.dart';

/// Estilo visual por marca (gradiente de cor) usado nas ilustrações.
class VehicleBrandStyle {
  final Color start;
  final Color end;

  const VehicleBrandStyle(this.start, this.end);

  List<Color> get gradient => [start, end];

  static VehicleBrandStyle forBrand(String brand) {
    final key = brand.toLowerCase().trim();
    switch (key) {
      case 'volkswagen':
        return const VehicleBrandStyle(Color(0xFF1E3D8F), Color(0xFF3B6FDD));
      case 'fiat':
        return const VehicleBrandStyle(Color(0xFF8E1B24), Color(0xFFD32F2F));
      case 'chevrolet':
        return const VehicleBrandStyle(Color(0xFF0F4C81), Color(0xFF1E7AC7));
      case 'hyundai':
        return const VehicleBrandStyle(Color(0xFF142B6B), Color(0xFF2E4BB0));
      case 'toyota':
        return const VehicleBrandStyle(Color(0xFF6E0C18), Color(0xFFB71C1C));
      case 'honda':
        return const VehicleBrandStyle(Color(0xFF90101F), Color(0xFFC62828));
      case 'nissan':
        return const VehicleBrandStyle(Color(0xFF5C0F00), Color(0xFFA3381E));
      case 'renault':
        return const VehicleBrandStyle(Color(0xFF8A6D00), Color(0xFFD9A400));
      case 'jeep':
        return const VehicleBrandStyle(Color(0xFF2C3539), Color(0xFF607D8B));
      case 'ford':
        return const VehicleBrandStyle(Color(0xFF003478), Color(0xFF1565C0));
      case 'ferrari':
        return const VehicleBrandStyle(Color(0xFFA31A1A), Color(0xFFDC2626));
      case 'porsche':
        return const VehicleBrandStyle(Color(0xFF1A1A1A), Color(0xFF4A4A4A));
      case 'lamborghini':
        return const VehicleBrandStyle(Color(0xFF5B4A00), Color(0xFFD4A017));
      case 'mclaren':
        return const VehicleBrandStyle(Color(0xFFCC4A00), Color(0xFFFF6B00));
      case 'aston martin':
        return const VehicleBrandStyle(Color(0xFF0A2F1A), Color(0xFF1B6B3A));
      case 'bentley':
        return const VehicleBrandStyle(Color(0xFF0F2A1A), Color(0xFF1A4D2E));
      case 'maserati':
        return const VehicleBrandStyle(Color(0xFF0F1F3A), Color(0xFF1E3A5F));
      case 'chevrolet camaro':
        return const VehicleBrandStyle(Color(0xFFB45309), Color(0xFFF59E0B));
      default:
        return const VehicleBrandStyle(Color(0xFF2A2E3A), Color(0xFF4A5468));
    }
  }
}

/// Corpo/tipo do carro usado para desenhar a silhueta.
/// Valores: hatch | sedan | suv | pickup | classic | supercar | sport_gt | suv_sport
const kBodyTypes = [
  'hatch',
  'sedan',
  'suv',
  'pickup',
  'classic',
  'supercar',
  'sport_gt',
  'suv_sport'
];

/// Ilustração vetorial própria (sem foto, sem direitos autorais):
/// gradiente da marca + silhueta estilizada por tipo de carroçaria.
class VehicleIllustration extends StatelessWidget {
  final String brand;
  final String bodyType;
  final double borderRadius;

  const VehicleIllustration({
    super.key,
    required this.brand,
    this.bodyType = 'hatch',
    this.borderRadius = 0,
  });

  @override
  Widget build(BuildContext context) {
    final style = VehicleBrandStyle.forBrand(brand);
    final type = kBodyTypes.contains(bodyType) ? bodyType : 'hatch';

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: style.gradient,
        ),
      ),
      child: CustomPaint(
        painter: _CarSilhouettePainter(type: type),
        size: Size.infinite,
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _CarSilhouettePainter extends CustomPainter {
  final String type;

  static const Color _silhouette = Color(0xE6141A2A);
  static const Color _glass = Color(0xFFC7D2E4);
  static const Color _tire = Color(0xFF0B0E15);
  static const Color _hub = Color(0xFFE6ECF7);

  const _CarSilhouettePainter({required this.type});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final w = size.width;
    final h = size.height;

    // Sombra no chão
    final groundPaint = Paint()..color = Colors.black.withOpacity(0.25);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.86),
        width: w * 0.78,
        height: h * 0.05,
      ),
      groundPaint,
    );

    // ── Corpo (silhueta) ──
    final carPaint = Paint()
      ..color = _silhouette
      ..style = PaintingStyle.fill;

    final carPath = _buildBody();
    carPath.transform(_scaleMatrix(w, h).storage);
    canvas.drawPath(carPath, carPaint);

    // Brilho suave no teto
    _drawRoofHighlight(canvas, carPath, size);

    // ── Vidros ──
    final glassPaint = Paint()..color = _glass.withOpacity(0.88);
    _drawWindows(canvas, glassPaint, size);

    // ── Rodas ──
    _drawWheels(canvas, size);
  }

  void _drawRoofHighlight(Canvas canvas, Path carPath, Size size) {
    final light = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.height * 0.02
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withOpacity(0.16);
    final bounds = carPath.getBounds();
    canvas.drawLine(
      Offset(bounds.left + size.width * 0.12, bounds.top + bounds.height * 0.16),
      Offset(bounds.right - size.width * 0.12, bounds.top + bounds.height * 0.16),
      light,
    );
  }

  void _drawWindows(Canvas canvas, Paint paint, Size size) {
    final glass = _windowsFor(type);
    for (final quad in glass) {
      final path = Path()
        ..moveTo(quad[0].dx * size.width, quad[0].dy * size.height)
        ..lineTo(quad[1].dx * size.width, quad[1].dy * size.height)
        ..lineTo(quad[2].dx * size.width, quad[2].dy * size.height)
        ..lineTo(quad[3].dx * size.width, quad[3].dy * size.height)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  void _drawWheels(Canvas canvas, Size size) {
    final wheels = _wheelsFor(type);
    for (final wData in wheels) {
      final cx = wData['cx']! * size.width;
      final cy = wData['cy']! * size.height;
      final r = wData['r']! * size.height;

      canvas.drawCircle(
        Offset(cx, cy),
        r,
        Paint()..color = _tire,
      );
      canvas.drawCircle(
        Offset(cx, cy),
        r * 0.52,
        Paint()..color = _hub,
      );
      canvas.drawCircle(
        Offset(cx, cy),
        r * 0.16,
        Paint()..color = _tire,
      );
    }
  }

  // ─────────────────────────────────────────────
  // Geometria normalizada (fração de 0..1)
  // ─────────────────────────────────────────────

  Path _buildBody() {
    final pts = _bodyPointsFor(type);
    final path = Path();
    path.moveTo(pts[0].dx, pts[0].dy);
    // Curva suave pelo teto usando controles centralizados.
    var last = pts[0];
    for (var i = 1; i < pts.length; i++) {
      final cur = pts[i];
      final mid = Offset((last.dx + cur.dx) / 2, (last.dy + cur.dy) / 2);
      path.quadraticBezierTo(last.dx, last.dy, mid.dx, mid.dy);
      last = cur;
    }
    path.close();
    return path;
  }

  static Matrix4 _scaleMatrix(double w, double h) {
    final m = Matrix4.identity();
    m[0] = w;
    m[5] = h;
    return m;
  }

  List<Offset> _bodyPointsFor(String type) {
    switch (type) {
      case 'classic':
        return const [
          Offset(0.06, 0.70),
          Offset(0.10, 0.62),
          Offset(0.24, 0.44),
          Offset(0.46, 0.27),
          Offset(0.68, 0.33),
          Offset(0.84, 0.46),
          Offset(0.92, 0.60),
          Offset(0.94, 0.70),
          Offset(0.88, 0.72),
          Offset(0.10, 0.72),
        ];
      case 'hatch':
        return const [
          Offset(0.08, 0.68),
          Offset(0.12, 0.58),
          Offset(0.26, 0.38),
          Offset(0.48, 0.28),
          Offset(0.70, 0.38),
          Offset(0.84, 0.52),
          Offset(0.92, 0.60),
          Offset(0.94, 0.68),
          Offset(0.88, 0.70),
          Offset(0.10, 0.70),
        ];
      case 'sedan':
        return const [
          Offset(0.05, 0.68),
          Offset(0.10, 0.56),
          Offset(0.28, 0.36),
          Offset(0.48, 0.28),
          Offset(0.68, 0.36),
          Offset(0.86, 0.52),
          Offset(0.94, 0.60),
          Offset(0.96, 0.66),
          Offset(0.90, 0.68),
          Offset(0.08, 0.68),
        ];
      case 'suv':
        return const [
          Offset(0.05, 0.70),
          Offset(0.10, 0.54),
          Offset(0.28, 0.34),
          Offset(0.48, 0.22),
          Offset(0.70, 0.30),
          Offset(0.86, 0.46),
          Offset(0.94, 0.58),
          Offset(0.95, 0.70),
          Offset(0.90, 0.72),
          Offset(0.08, 0.72),
        ];
      case 'pickup':
        return const [
          Offset(0.05, 0.70),
          Offset(0.10, 0.56),
          Offset(0.24, 0.42),
          Offset(0.44, 0.30),
          Offset(0.62, 0.34),
          Offset(0.64, 0.58),
          Offset(0.94, 0.58),
          Offset(0.94, 0.70),
          Offset(0.90, 0.72),
          Offset(0.08, 0.72),
        ];
      // ── Superesportivos: silhueta baixa, larga e agressiva ──
      case 'supercar':
        return const [
          Offset(0.03, 0.68),
          Offset(0.06, 0.58),
          Offset(0.18, 0.42),
          Offset(0.34, 0.28),
          Offset(0.52, 0.22),
          Offset(0.72, 0.26),
          Offset(0.88, 0.40),
          Offset(0.94, 0.56),
          Offset(0.96, 0.66),
          Offset(0.92, 0.69),
          Offset(0.05, 0.69),
        ];
      case 'sport_gt':
        return const [
          Offset(0.04, 0.68),
          Offset(0.08, 0.56),
          Offset(0.22, 0.36),
          Offset(0.40, 0.24),
          Offset(0.60, 0.22),
          Offset(0.78, 0.30),
          Offset(0.90, 0.46),
          Offset(0.95, 0.60),
          Offset(0.96, 0.67),
          Offset(0.91, 0.69),
          Offset(0.06, 0.69),
        ];
      case 'suv_sport':
        return const [
          Offset(0.04, 0.70),
          Offset(0.08, 0.52),
          Offset(0.24, 0.32),
          Offset(0.44, 0.20),
          Offset(0.66, 0.22),
          Offset(0.84, 0.34),
          Offset(0.92, 0.50),
          Offset(0.95, 0.62),
          Offset(0.96, 0.70),
          Offset(0.91, 0.72),
          Offset(0.07, 0.72),
        ];
      default:
        return const [
          Offset(0.08, 0.68),
          Offset(0.12, 0.58),
          Offset(0.26, 0.38),
          Offset(0.48, 0.28),
          Offset(0.70, 0.38),
          Offset(0.84, 0.52),
          Offset(0.92, 0.60),
          Offset(0.94, 0.68),
          Offset(0.88, 0.70),
          Offset(0.10, 0.70),
        ];
    }
  }

  List<List<Offset>> _windowsFor(String type) {
    // Vidros = pares de quadriláteros (traseiro e dianteiro)
    switch (type) {
      case 'classic':
        return const [
          [
            Offset(0.30, 0.40),
            Offset(0.38, 0.31),
            Offset(0.58, 0.31),
            Offset(0.58, 0.40),
          ],
        ];
      case 'hatch':
        return const [
          [
            Offset(0.28, 0.41),
            Offset(0.34, 0.31),
            Offset(0.46, 0.30),
            Offset(0.50, 0.41),
          ],
          [
            Offset(0.52, 0.41),
            Offset(0.52, 0.30),
            Offset(0.66, 0.31),
            Offset(0.74, 0.42),
          ],
        ];
      case 'sedan':
        return const [
          [
            Offset(0.22, 0.39),
            Offset(0.34, 0.30),
            Offset(0.46, 0.30),
            Offset(0.50, 0.39),
          ],
          [
            Offset(0.52, 0.39),
            Offset(0.52, 0.30),
            Offset(0.66, 0.31),
            Offset(0.76, 0.42),
          ],
        ];
      case 'suv':
        return const [
          [
            Offset(0.22, 0.39),
            Offset(0.34, 0.26),
            Offset(0.46, 0.24),
            Offset(0.50, 0.37),
          ],
          [
            Offset(0.52, 0.37),
            Offset(0.54, 0.26),
            Offset(0.68, 0.30),
            Offset(0.76, 0.42),
          ],
        ];
      case 'pickup':
        return const [
          [
            Offset(0.24, 0.40),
            Offset(0.34, 0.32),
            Offset(0.58, 0.34),
            Offset(0.60, 0.46),
          ],
        ];
      case 'supercar':
        return const [
          [
            Offset(0.20, 0.38),
            Offset(0.32, 0.26),
            Offset(0.50, 0.22),
            Offset(0.56, 0.34),
          ],
          [
            Offset(0.58, 0.34),
            Offset(0.60, 0.22),
            Offset(0.78, 0.28),
            Offset(0.86, 0.38),
          ],
        ];
      case 'sport_gt':
        return const [
          [
            Offset(0.24, 0.36),
            Offset(0.36, 0.24),
            Offset(0.50, 0.22),
            Offset(0.54, 0.34),
          ],
          [
            Offset(0.56, 0.34),
            Offset(0.58, 0.22),
            Offset(0.74, 0.26),
            Offset(0.84, 0.38),
          ],
        ];
      case 'suv_sport':
        return const [
          [
            Offset(0.24, 0.36),
            Offset(0.34, 0.24),
            Offset(0.50, 0.20),
            Offset(0.54, 0.34),
          ],
          [
            Offset(0.56, 0.34),
            Offset(0.58, 0.20),
            Offset(0.72, 0.22),
            Offset(0.82, 0.36),
          ],
        ];
      default:
        return const [];
    }
  }

  List<Map<String, double>> _wheelsFor(String type) {
    switch (type) {
      case 'classic':
        return const [
          {'cx': 0.26, 'cy': 0.73, 'r': 0.07},
          {'cx': 0.74, 'cy': 0.73, 'r': 0.07},
        ];
      case 'suv':
        return const [
          {'cx': 0.26, 'cy': 0.75, 'r': 0.09},
          {'cx': 0.74, 'cy': 0.75, 'r': 0.09},
        ];
      case 'pickup':
        return const [
          {'cx': 0.30, 'cy': 0.74, 'r': 0.075},
          {'cx': 0.72, 'cy': 0.74, 'r': 0.075},
        ];
      case 'supercar':
        return const [
          {'cx': 0.25, 'cy': 0.71, 'r': 0.085},
          {'cx': 0.75, 'cy': 0.71, 'r': 0.085},
        ];
      case 'sport_gt':
        return const [
          {'cx': 0.26, 'cy': 0.71, 'r': 0.08},
          {'cx': 0.74, 'cy': 0.71, 'r': 0.08},
        ];
      case 'suv_sport':
        return const [
          {'cx': 0.27, 'cy': 0.74, 'r': 0.088},
          {'cx': 0.73, 'cy': 0.74, 'r': 0.088},
        ];
      case 'hatch':
      case 'sedan':
      default:
        return const [
          {'cx': 0.26, 'cy': 0.71, 'r': 0.075},
          {'cx': 0.74, 'cy': 0.71, 'r': 0.075},
        ];
    }
  }

  @override
  bool shouldRepaint(covariant _CarSilhouettePainter oldDelegate) {
    return oldDelegate.type != type;
  }
}