import 'package:flutter/widgets.dart';

/// App icon set, backed by the bundled Lucide icon font.
///
/// We deliberately do NOT use `package:lucide_icons_flutter`'s `LucideIcons`
/// class directly: it declares ~27k `static const IconData` fields in a single
/// class, and on Flutter web in debug mode (DDC) the first access to any of them
/// forces the whole library to link at once, overflowing the JS stack
/// (StackOverflowError). Declaring only the icons we use sidesteps that entirely
/// while reusing the same font glyphs (fontFamily 'Lucide', shipped by the package).
///
/// To add an icon: find its codepoint in
/// package:lucide_icons_flutter/lucide_icons.dart and add a field here.
abstract final class AppIcons {
  static const IconData activity = IconData(57400, fontFamily: 'Lucide', fontPackage: 'lucide_icons_flutter');
  static const IconData arrowLeft = IconData(57416, fontFamily: 'Lucide', fontPackage: 'lucide_icons_flutter');
  static const IconData arrowRight = IconData(57417, fontFamily: 'Lucide', fontPackage: 'lucide_icons_flutter');
  static const IconData award = IconData(57423, fontFamily: 'Lucide', fontPackage: 'lucide_icons_flutter');
  static const IconData bookOpen = IconData(57439, fontFamily: 'Lucide', fontPackage: 'lucide_icons_flutter');
  static const IconData bot = IconData(57787, fontFamily: 'Lucide', fontPackage: 'lucide_icons_flutter');
  static const IconData brain = IconData(58310, fontFamily: 'Lucide', fontPackage: 'lucide_icons_flutter');
  static const IconData calendar = IconData(57443, fontFamily: 'Lucide', fontPackage: 'lucide_icons_flutter');
  static const IconData chartColumn = IconData(58019, fontFamily: 'Lucide', fontPackage: 'lucide_icons_flutter');
  static const IconData check = IconData(57452, fontFamily: 'Lucide', fontPackage: 'lucide_icons_flutter');
  static const IconData chevronDown = IconData(57453, fontFamily: 'Lucide', fontPackage: 'lucide_icons_flutter');
  static const IconData chevronLeft = IconData(57454, fontFamily: 'Lucide', fontPackage: 'lucide_icons_flutter');
  static const IconData chevronRight = IconData(57455, fontFamily: 'Lucide', fontPackage: 'lucide_icons_flutter');
  static const IconData chevronUp = IconData(57456, fontFamily: 'Lucide', fontPackage: 'lucide_icons_flutter');
  static const IconData circle = IconData(57462, fontFamily: 'Lucide', fontPackage: 'lucide_icons_flutter');
  static const IconData circleAlert = IconData(57463, fontFamily: 'Lucide', fontPackage: 'lucide_icons_flutter');
  static const IconData circleCheck = IconData(57894, fontFamily: 'Lucide', fontPackage: 'lucide_icons_flutter');
  static const IconData circleCheckBig = IconData(57468, fontFamily: 'Lucide', fontPackage: 'lucide_icons_flutter');
  static const IconData circlePlay = IconData(57472, fontFamily: 'Lucide', fontPackage: 'lucide_icons_flutter');
  static const IconData circleX = IconData(57476, fontFamily: 'Lucide', fontPackage: 'lucide_icons_flutter');
  static const IconData clock = IconData(57479, fontFamily: 'Lucide', fontPackage: 'lucide_icons_flutter');
  static const IconData copy = IconData(57502, fontFamily: 'Lucide', fontPackage: 'lucide_icons_flutter');
  static const IconData download = IconData(57522, fontFamily: 'Lucide', fontPackage: 'lucide_icons_flutter');
  static const IconData eye = IconData(57530, fontFamily: 'Lucide', fontPackage: 'lucide_icons_flutter');
  static const IconData eyeOff = IconData(57531, fontFamily: 'Lucide', fontPackage: 'lucide_icons_flutter');
  static const IconData fileQuestion = IconData(58146, fontFamily: 'Lucide', fontPackage: 'lucide_icons_flutter');
  static const IconData fileText = IconData(57548, fontFamily: 'Lucide', fontPackage: 'lucide_icons_flutter');
  static const IconData flag = IconData(57553, fontFamily: 'Lucide', fontPackage: 'lucide_icons_flutter');
  static const IconData flame = IconData(57554, fontFamily: 'Lucide', fontPackage: 'lucide_icons_flutter');
  static const IconData gift = IconData(57569, fontFamily: 'Lucide', fontPackage: 'lucide_icons_flutter');
  static const IconData gripVertical = IconData(57579, fontFamily: 'Lucide', fontPackage: 'lucide_icons_flutter');
  static const IconData heartHandshake = IconData(58071, fontFamily: 'Lucide', fontPackage: 'lucide_icons_flutter');
  static const IconData history = IconData(57845, fontFamily: 'Lucide', fontPackage: 'lucide_icons_flutter');
  static const IconData house = IconData(57589, fontFamily: 'Lucide', fontPackage: 'lucide_icons_flutter');
  static const IconData layoutDashboard = IconData(57793, fontFamily: 'Lucide', fontPackage: 'lucide_icons_flutter');
  static const IconData listChecks = IconData(57808, fontFamily: 'Lucide', fontPackage: 'lucide_icons_flutter');
  static const IconData lock = IconData(57611, fontFamily: 'Lucide', fontPackage: 'lucide_icons_flutter');
  static const IconData logOut = IconData(57614, fontFamily: 'Lucide', fontPackage: 'lucide_icons_flutter');
  static const IconData mail = IconData(57615, fontFamily: 'Lucide', fontPackage: 'lucide_icons_flutter');
  static const IconData menu = IconData(57621, fontFamily: 'Lucide', fontPackage: 'lucide_icons_flutter');
  static const IconData messageCircle = IconData(57622, fontFamily: 'Lucide', fontPackage: 'lucide_icons_flutter');
  static const IconData minus = IconData(57628, fontFamily: 'Lucide', fontPackage: 'lucide_icons_flutter');
  static const IconData moon = IconData(57630, fontFamily: 'Lucide', fontPackage: 'lucide_icons_flutter');
  static const IconData play = IconData(57660, fontFamily: 'Lucide', fontPackage: 'lucide_icons_flutter');
  static const IconData plus = IconData(57661, fontFamily: 'Lucide', fontPackage: 'lucide_icons_flutter');
  static const IconData search = IconData(57681, fontFamily: 'Lucide', fontPackage: 'lucide_icons_flutter');
  static const IconData send = IconData(57682, fontFamily: 'Lucide', fontPackage: 'lucide_icons_flutter');
  static const IconData settings = IconData(57684, fontFamily: 'Lucide', fontPackage: 'lucide_icons_flutter');
  static const IconData share2 = IconData(57686, fontFamily: 'Lucide', fontPackage: 'lucide_icons_flutter');
  static const IconData shield = IconData(57688, fontFamily: 'Lucide', fontPackage: 'lucide_icons_flutter');
  static const IconData shieldCheck = IconData(57855, fontFamily: 'Lucide', fontPackage: 'lucide_icons_flutter');
  static const IconData sparkles = IconData(58386, fontFamily: 'Lucide', fontPackage: 'lucide_icons_flutter');
  static const IconData star = IconData(57718, fontFamily: 'Lucide', fontPackage: 'lucide_icons_flutter');
  static const IconData sun = IconData(57720, fontFamily: 'Lucide', fontPackage: 'lucide_icons_flutter');
  static const IconData target = IconData(57728, fontFamily: 'Lucide', fontPackage: 'lucide_icons_flutter');
  static const IconData trash2 = IconData(57742, fontFamily: 'Lucide', fontPackage: 'lucide_icons_flutter');
  static const IconData trendingUp = IconData(57745, fontFamily: 'Lucide', fontPackage: 'lucide_icons_flutter');
  static const IconData triangleAlert = IconData(57747, fontFamily: 'Lucide', fontPackage: 'lucide_icons_flutter');
  static const IconData trophy = IconData(58227, fontFamily: 'Lucide', fontPackage: 'lucide_icons_flutter');
  static const IconData user = IconData(57759, fontFamily: 'Lucide', fontPackage: 'lucide_icons_flutter');
  static const IconData users = IconData(57764, fontFamily: 'Lucide', fontPackage: 'lucide_icons_flutter');
  static const IconData x = IconData(57778, fontFamily: 'Lucide', fontPackage: 'lucide_icons_flutter');
  static const IconData zap = IconData(57780, fontFamily: 'Lucide', fontPackage: 'lucide_icons_flutter');
}
