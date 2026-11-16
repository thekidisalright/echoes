/// Data curta: "16/11/2026".
String formatShortDate(DateTime date) =>
    '${_two(date.day)}/${_two(date.month)}/${date.year}';

String _two(int value) => value.toString().padLeft(2, '0');
