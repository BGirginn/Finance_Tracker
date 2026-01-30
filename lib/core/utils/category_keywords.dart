class CategoryKeywords {
  static final Map<String, List<String>> _keywordMap = {
    'Yemek': ['restoran', 'yemek', 'kahvaltı', 'öğle', 'akşam', 'fast food', 'mcdonald', 'burger', 'pizza'],
    'Market': ['market', 'migros', 'bim', 'a101', 'şok', 'carrefour', 'gıda', 'alışveriş'],
    'Ulaşım': ['otobüs', 'metro', 'taksi', 'uber', 'benzin', 'yakıt', 'park', 'otopark', 'toll'],
    'Faturalar': ['elektrik', 'su', 'doğalgaz', 'internet', 'telefon', 'fatura', 'turkcell', 'vodafone'],
    'Eğlence': ['sinema', 'tiyatro', 'konser', 'müze', 'park', 'eğlence', 'oyun'],
    'Sağlık': ['eczane', 'doktor', 'hastane', 'ilaç', 'sağlık', 'muayene'],
    'Eğitim': ['kitap', 'kurs', 'okul', 'üniversite', 'eğitim', 'ders'],
    'Giyim': ['giyim', 'kıyafet', 'ayakkabı', 'mağaza', 'h&m', 'zara', 'lc waikiki'],
    'Kira': ['kira', 'ev', 'konut'],
    'Maaş': ['maaş', 'salary', 'wage', 'gelir'],
    'Yatırım': ['yatırım', 'hisse', 'borsa', 'crypto', 'bitcoin', 'ethereum'],
  };

  static String? suggestCategory(String note) {
    if (note.isEmpty) return null;

    final lowerNote = note.toLowerCase();
    
    for (final entry in _keywordMap.entries) {
      for (final keyword in entry.value) {
        if (lowerNote.contains(keyword.toLowerCase())) {
          return entry.key;
        }
      }
    }

    return null;
  }

  static List<String> getAllCategories() {
    return _keywordMap.keys.toList()..sort();
  }
}
