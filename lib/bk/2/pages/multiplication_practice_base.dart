part of 'multiplication_practice_page.dart';

/// 共用欄位與基底 State
abstract class _MultiplicationPracticeBase
    extends State<MultiplicationPracticePage> {
  final Random _random = Random();
  final TextEditingController _answerController = TextEditingController();
  final FocusNode _answerFocus = FocusNode();

  late int _a;
  late int _b;
  String _message = '';
  Color _messageColor = Colors.black;

  // 音效播放器
  final AudioPlayer _player = AudioPlayer();

  // 設定：位數
  int _digitsA = 1; // 第一個數字的位數：1~9
  int _digitsB = 1; // 第二個數字的位數：1~9

  // 一次要練習幾題
  int _questionsPerSet = 5;
  int _answeredCount = 0; // 本組已完成題數

  // 選擇的運算種類（預設乘法）
  Operation _operation = Operation.multiply;

  // 是否在設定頁
  bool _inSettings = true;

  // 手寫板設定
  bool _enableHandwriting = true;
  double _strokeWidth = 4.0;

  // 手寫板的點
  final List<Offset?> _points = [];

  // 上一次 onPanUpdate 的時間（毫秒），用來節流，避免太多 setState
  int _lastPanUpdateMs = 0;

  @override
  void dispose() {
    _answerController.dispose();
    _answerFocus.dispose();
    _player.dispose();
    super.dispose();
  }
}

