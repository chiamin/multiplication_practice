/// 四則運算種類
enum Operation {
  add,       // 加法
  subtract,  // 減法
  multiply,  // 乘法
  divide,    // 除法
}

/// 顯示用標籤
extension OperationLabel on Operation {
  String get label {
    switch (this) {
      case Operation.add:
        return '加法';
      case Operation.subtract:
        return '減法';
      case Operation.multiply:
        return '乘法';
      case Operation.divide:
        return '除法';
    }
  }
}

