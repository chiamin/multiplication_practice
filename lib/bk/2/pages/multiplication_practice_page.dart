import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

import '../models/operation.dart';
import '../widgets/handwriting_painter.dart';
import '../widgets/rabbits_celebration.dart';

part 'multiplication_practice_base.dart';
part 'multiplication_practice_logic.dart';
part 'multiplication_practice_ui.dart';

class MultiplicationPracticePage extends StatefulWidget {
  const MultiplicationPracticePage({super.key});

  @override
  State<MultiplicationPracticePage> createState() =>
      _MultiplicationPracticePageState();
}

class _MultiplicationPracticePageState extends _MultiplicationPracticeBase
    with MultiplicationPracticeLogic, MultiplicationPracticeUI {}

