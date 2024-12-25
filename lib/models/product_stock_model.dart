class ProductStock {
  int? page;
  int? perPage;
  int? totalPages;
  int? totalItems;
  List<ProductStockItem>? items; // Renamed to ProductStockItem

  ProductStock({
    this.page,
    this.perPage,
    this.totalPages,
    this.totalItems,
    this.items,
  });

  ProductStock.fromJson(Map<String, dynamic> json) {
    page = json['page'];
    perPage = json['perPage'];
    totalPages = json['totalPages'];
    totalItems = json['totalItems'];
    if (json['items'] != null) {
      items = List<ProductStockItem>.from(json['items'].map((v) => ProductStockItem.fromJson(v)));
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

class ProductStockItem {
  String? collectionId;
  String? collectionName;
  String? id;
  String? product;
  String? outlet;
  int? quantity;
  String? created;
  String? updated;

  ProductStockItem({
    this.collectionId,
    this.collectionName,
    this.id,
    this.product,
    this.outlet,
    this.quantity,
    this.created,
    this.updated,
  });

  ProductStockItem.fromJson(Map<String, dynamic> json) {
    collectionId = json['collectionId'];
    collectionName = json['collectionName'];
    id = json['id'];
    product = json['product'];
    outlet = json['outlet'];
    quantity = json['quantity'];
    created = json['created'];
    updated = json['updated'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['collectionId'] = collectionId;
    data['collectionName'] = collectionName;
    data['id'] = id;
    data['product'] = product;
    data['outlet'] = outlet;
    data['quantity'] = quantity;
    data['created'] = created;
    data['updated'] = updated;
    return data;
  }
}