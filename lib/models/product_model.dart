class ProductModel {
  int? page;
  int? perPage;
  int? totalPages;
  int? totalItems;
  List<ProductItem>? items; // Renamed to ProductItem

  ProductModel({
    this.page,
    this.perPage,
    this.totalPages,
    this.totalItems,
    this.items,
  });

  ProductModel.fromJson(Map<String, dynamic> json) {
    page = json['page'];
    perPage = json['perPage'];
    totalPages = json['totalPages'];
    totalItems = json['totalItems'];
    if (json['items'] != null) {
      items = List<ProductItem>.from(json['items'].map((v) => ProductItem.fromJson(v)));
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

class ProductItem {
  String? collectionId;
  String? collectionName;
  String? id;
  String? name;
  String? category;
  int? price;
  String? picture;
  String? created;
  String? updated;

  ProductItem({
    this.collectionId,
    this.collectionName,
    this.id,
    this.name,
    this.category,
    this.price,
    this.picture,
    this.created,
    this.updated,
  });

  ProductItem.fromJson(Map<String, dynamic> json) {
    collectionId = json['collectionId'];
    collectionName = json['collectionName'];
    id = json['id'];
    name = json['name'];
    category = json['category'];
    price = json['price'];
    picture = json['picture'];
    created = json['created'];
    updated = json['updated'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['collectionId'] = collectionId;
    data['collectionName'] = collectionName;
    data['id'] = id;
    data['name'] = name;
    data['category'] = category;
    data['price'] = price;
    data['picture'] = picture;
    data['created'] = created;
    data['updated'] = updated;
    return data;
  }
}