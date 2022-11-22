class CountData {
  String name;
  int count;
  bool status;
  bool timeEnd;

  CountData(this.name, this.count, this.status, this.timeEnd);

  CountData.fromJson(Map<String, dynamic> json)
      : name = json['name'],
        count = json['count'],
        status = json['status'],
        timeEnd = json['timeEnd'];

  Map<String, dynamic> toJson() => {
        'name': name,
        'count': count,
        'status': status,
        'timeEnd': timeEnd,
      };
}
