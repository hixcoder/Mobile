import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart';

void main() {
  runApp(const CalculatorApp());
}

class CalculatorApp extends StatelessWidget {
  const CalculatorApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculator',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const CalculatorPage(),
    );
  }
}

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({Key? key}) : super(key: key);

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  String _expression = "0";
  String _result = "0";

  // Method to calculate the result
  void _calculateResult() {
    try {
      // Handle edge cases
      if (_expression.isEmpty ||
          (_expression.length == 1 && _expression == "0") ||
          _endsWithOperator(_expression)) {
        return;
      }

      // Parse the expression
      Parser p = Parser();

      // Replace 'x' with '*' for the parser if needed
      String finalExpression = _expression;

      // Try to evaluate the expression (v3.1.0 API)
      Expression exp = p.parse(finalExpression);
      RealEvaluator evaluator = RealEvaluator();
      num result = evaluator.evaluate(exp);
      double eval = result.toDouble();

      // Handle infinity or NaN results
      if (eval.isInfinite || eval.isNaN) {
        setState(() {
          _result = "Error";
        });
        return;
      }

      // Format the result
      String resultStr = eval.toString();
      if (resultStr.endsWith('.0')) {
        resultStr = resultStr.substring(0, resultStr.length - 2);
      }

      setState(() {
        _result = resultStr;
      });
    } catch (e) {
      setState(() {
        _result = "Error";
        print("Calculation error: $e");
      });
    }
  }

  // Check if string ends with an operator
  bool _endsWithOperator(String str) {
    if (str.isEmpty) return false;
    return ['+', '-', '*', '/', '.'].contains(str[str.length - 1]);
  }

  // Check if string has consecutive operators
  bool _hasConsecutiveOperators(String str, String op) {
    if (str.isEmpty) return false;
    if (['+', '*', '/'].contains(op) && _endsWithOperator(str)) {
      return true;
    }
    return false;
  }

  // Method to handle button press
  void _buttonPressed(String buttonText) {
    print('button pressed: $buttonText');

    setState(() {
      if (buttonText == 'AC') {
        // Clear all
        _expression = "0";
        _result = "0";
      } else if (buttonText == 'C') {
        // Clear last character
        if (_expression.length > 1) {
          _expression = _expression.substring(0, _expression.length - 1);
        } else {
          _expression = "0";
        }
      } else if (buttonText == '=') {
        // Calculate result
        _calculateResult();
      } else {
        // Handle negation - allow negative number at the beginning
        if (buttonText == '-' && _expression == "0") {
          _expression = buttonText;
          return;
        }

        // Handle decimal point
        if (buttonText == '.' &&
            _expression.contains('.') &&
            !_expression.contains(RegExp(r'[+\-*/]'))) {
          // Avoid duplicate decimal in same number
          return;
        }

        // Handle consecutive operators
        if (_hasConsecutiveOperators(_expression, buttonText)) {
          // Replace last operator with new one
          _expression =
              _expression.substring(0, _expression.length - 1) + buttonText;
        } else {
          // Normal input
          if (_expression == "0" && buttonText != '.') {
            _expression = buttonText;
          } else {
            _expression += buttonText;
          }
        }
      }
    });

    // Update result in real-time as expression changes
    if (buttonText != '=' && buttonText != 'AC' && buttonText != 'C') {
      _calculateResult();
    }
  }

  // Method to build a calculator button
  Widget _buildButton(String buttonText, {Color textColor = Colors.black}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child: TextButton(
          style: TextButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4.0),
            ),
          ),
          onPressed: () => _buttonPressed(buttonText),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              buttonText,
              style: TextStyle(fontSize: 24, color: textColor),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Check if we're in landscape mode
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculator'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: isLandscape ? _buildLandscapeLayout() : _buildPortraitLayout(),
      ),
    );
  }

  // Portrait layout
  Widget _buildPortraitLayout() {
    return Column(
      children: [
        // Display area for expression and result - always at the top
        _buildDisplayArea(),

        // Calculator buttons
        Expanded(
          child: _buildButtonsGrid(),
        ),
      ],
    );
  }

  // Landscape layout
  Widget _buildLandscapeLayout() {
    return Column(
      children: [
        // Display area - always at the top even in landscape
        _buildDisplayArea(),

        // Buttons in a grid that takes remaining space
        Expanded(
          child: _buildButtonsGrid(),
        ),
      ],
    );
  }

  // Display area widget
  Widget _buildDisplayArea() {
    return Container(
      color: Colors.grey[200],
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Take minimum height needed
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _expression, // Expression field
            style: TextStyle(fontSize: 24, color: Colors.grey[700]),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Text(
            _result, // Result field
            style: const TextStyle(fontSize: 48),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Buttons grid widget
  Widget _buildButtonsGrid() {
    return Container(
      color: Colors.grey[300],
      child: OrientationBuilder(
        builder: (context, orientation) {
          if (orientation == Orientation.landscape) {
            // Landscape grid layout - optimized for width
            return Row(
              children: [
                // Left half of buttons
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildButton('7'),
                            _buildButton('8'),
                            _buildButton('9'),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildButton('4'),
                            _buildButton('5'),
                            _buildButton('6'),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildButton('1'),
                            _buildButton('2'),
                            _buildButton('3'),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildButton('0'),
                            _buildButton('.'),
                            _buildButton('00'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Right half of buttons (operators)
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildButton('C', textColor: Colors.red),
                            _buildButton('AC', textColor: Colors.red),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildButton('+', textColor: Colors.blue),
                            _buildButton('-', textColor: Colors.blue),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildButton('*', textColor: Colors.blue),
                            _buildButton('/', textColor: Colors.blue),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildButton('=', textColor: Colors.blue),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          } else {
            // Portrait grid layout - standard calculator layout
            return Column(
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildButton('7'),
                      _buildButton('8'),
                      _buildButton('9'),
                      _buildButton('C', textColor: Colors.red),
                      _buildButton('AC', textColor: Colors.red),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildButton('4'),
                      _buildButton('5'),
                      _buildButton('6'),
                      _buildButton('+', textColor: Colors.blue),
                      _buildButton('-', textColor: Colors.blue),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildButton('1'),
                      _buildButton('2'),
                      _buildButton('3'),
                      _buildButton('*', textColor: Colors.blue),
                      _buildButton('/', textColor: Colors.blue),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildButton('0'),
                      _buildButton('.'),
                      _buildButton('00'),
                      _buildButton('=', textColor: Colors.blue),
                    ],
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}
