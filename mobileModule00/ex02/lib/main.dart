import 'package:flutter/material.dart';

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
  // Method to handle button press
  void _buttonPressed(String buttonText) {
    print('button pressed: $buttonText');
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
            "0", // Expression field
            style: TextStyle(fontSize: 24, color: Colors.grey[700]),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          const Text(
            "0", // Result field
            style: TextStyle(fontSize: 48),
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
