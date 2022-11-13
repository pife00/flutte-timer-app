class CountData {
  String name;
  int count;

  CountData(this.name, this.count);

  CountData.fromJson(Map<String, dynamic> json)
      : name = json['name'],
        count = json['count'];

  Map<String, dynamic> toJson() => {
        'name': name,
        'count': count,
      };
}
