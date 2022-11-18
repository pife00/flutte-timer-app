class CountData {
  String name;
  int count;
  bool status;

  CountData(this.name, this.count, this.status);

  CountData.fromJson(Map<String, dynamic> json)
      : name = json['name'],
        count = json['count'],
        status = json['status'];

  Map<String, dynamic> toJson() => {
        'name': name,
        'count': count,
        'status': status,
      };
}
