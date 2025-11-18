import 'package:flutter/material.dart';

class RatingDialog extends StatefulWidget {
  final String movieTitle;
  final Function(int rating, String review) onSubmit;
  final int? initialRating;
  final String? initialReview;

  const RatingDialog({
    super.key,
    required this.movieTitle,
    required this.onSubmit,
    this.initialRating,
    this.initialReview,
  });

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  int _rating = 0;
  final TextEditingController _reviewController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating ?? 0;
    _reviewController.text = widget.initialReview ?? '';
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF221A2A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Avaliar Filme',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.movieTitle,
              style: const TextStyle(
                color: Color(0xFF8C8696),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _rating = index + 1;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Icon(
                      index < _rating ? Icons.star : Icons.star_border,
                      color: const Color(0xFFFFC107),
                      size: 32,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            if (_rating > 0) ...[
              Text(
                _getRatingText(_rating),
                style: const TextStyle(
                  color: Color(0xFF8C8696),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),
            ],
            TextField(
              controller: _reviewController,
              maxLines: 3,
              maxLength: 200,
              decoration: InputDecoration(
                hintText: 'Escreva um comentário (opcional)...',
                hintStyle: const TextStyle(color: Color(0xFF8C8696)),
                filled: true,
                fillColor: const Color(0xFF191221),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
                counterStyle: const TextStyle(color: Color(0xFF8C8696)),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF8C8696),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _rating > 0 ? () {
                      widget.onSubmit(_rating, _reviewController.text.trim());
                      Navigator.of(context).pop();
                    } : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6B45A1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Salvar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'Muito ruim';
      case 2:
        return 'Ruim';
      case 3:
        return 'Regular';
      case 4:
        return 'Bom';
      case 5:
        return 'Excelente';
      default:
        return '';
    }
  }
}
