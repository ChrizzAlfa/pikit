class OutletModels {
  int? page;
  int? perPage;
  int? totalPages;
  int? totalItems;
  List<Items>? items;

  OutletModels(
      {this.page, this.perPage, this.totalPages, this.totalItems, this.items});

  OutletModels.fromJson(Map<String, dynamic> json) {
    page = json['page'];
    perPage = json['perPage'];
    totalPages = json['totalPages'];
    totalItems = json['totalItems'];
    if (json['items'] != null) {
      items = <Items>[];
      json['items'].forEach((v) {
        items!.add(Items.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['page'] = page;
    data['perPage'] = perPage;
    data['totalPages'] = totalPages;
    data['totalItems'] = totalItems;
    if (items != null) {
      data['items'] = items!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Items {
  String? collectionId;
  String? collectionName;
  String? id;
  String? retail;
  String? address;
  String? created;
  String? updated;

  Items(
      {this.collectionId,
      this.collectionName,
      this.id,
      this.retail,
      this.address,
      this.created,
      this.updated});

  Items.fromJson(Map<String, dynamic> json) {
    collectionId = json['collectionId'];
    collectionName = json['collectionName'];
    id = json['id'];
    retail = json['retail'];
    address = json['address'];
    created = json['created'];
    updated = json['updated'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['collectionId'] = collectionId;
    data['collectionName'] = collectionName;
    data['id'] = id;
    data['retail'] = retail;
    data['address'] = address;
    data['created'] = created;
    data['updated'] = updated;
    return data;
  }
}