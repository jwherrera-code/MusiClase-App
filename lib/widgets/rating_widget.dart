import 'package:flutter/material.dart';

class RatingWidget extends StatefulWidget {
  final double initialRating;
  final Function(double) onRatingChanged;
  final bool enabled;

  const RatingWidget({
    Key? key,
    this.initialRating = 0.0,
    required this.onRatingChanged,
    this.enabled = true,
  }) : super(key: key);

  @override
  _RatingWidgetState createState() => _RatingWidgetState();
}

class _RatingWidgetState extends State<RatingWidget> {
  late double _currentRating;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.initialRating;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return IconButton(
          icon: Icon(
            index < _currentRating.floor() ? Icons.star : Icons.star_border,
            color: Colors.amber,
            size: 30,
          ),
          onPressed: widget.enabled
              ? () {
                  setState(() {
                    _currentRating = index + 1.0;
                  });
                  widget.onRatingChanged(_currentRating);
                }
              : null,
        );
      }),
    );
  }
}