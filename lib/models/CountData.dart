class countData {
  String name;
  int count;
  countData(this.name, this.count);

  Map<String, dynamic> toJson() => {
        'name': name,
        'count': count,
      };
}
