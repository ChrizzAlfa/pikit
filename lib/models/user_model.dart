class UserModel {
  int? page;
  int? perPage;
  int? totalPages;
  int? totalItems;
  List<Items>? items;

  UserModel(
      {this.page, this.perPage, this.totalPages, this.totalItems, this.items});

  UserModel.fromJson(Map<String, dynamic> json) {
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
  String? email;
  bool? emailVisibility;
  bool? verified;
  String? name;
  String? avatar;
  List<String>? cart;
  String? created;
  String? updated;

  Items(
      {this.collectionId,
      this.collectionName,
      this.id,
      this.email,
      this.emailVisibility,
      this.verified,
      this.name,
      this.avatar,
      this.cart,
      this.created,
      this.updated});

  Items.fromJson(Map<String, dynamic> json) {
    collectionId = json['collectionId'];
    collectionName = json['collectionName'];
    id = json['id'];
    email = json['email'];
    emailVisibility = json['emailVisibility'];
    verified = json['verified'];
    name = json['name'];
    avatar = json['avatar'];
    cart = json['cart'].cast<String>();
    created = json['created'];
    updated = json['updated'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['collectionId'] = collectionId;
    data['collectionName'] = collectionName;
    data['id'] = id;
    data['email'] = email;
    data['emailVisibility'] = emailVisibility;
    data['verified'] = verified;
    data['name'] = name;
    data['avatar'] = avatar;
    data['cart'] = cart;
    data['created'] = created;
    data['updated'] = updated;
    return data;
  }
}
