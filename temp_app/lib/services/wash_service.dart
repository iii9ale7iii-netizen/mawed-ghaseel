import '../models/wash_model.dart';

class WashService {
  static List<WashModel> washes = [
    WashModel(
      washId: '1',
      washName: 'مغسلة النقاء',
      ownerName: 'محمد',
      phone: '0500000001',
      email: 'wash1@test.com',
      washType: 'ثابتة',
      city: 'الرياض',
      address: 'حي الياسمين',
    ),

    WashModel(
      washId: '2',
      washName: 'مغسلة البريق',
      ownerName: 'خالد',
      phone: '0500000002',
      email: 'wash2@test.com',
      washType: 'متنقلة',
      city: 'الرياض',
      address: 'حي الملقا',
    ),
  ];
}
