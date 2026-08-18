import '../models/athlete.dart';
import '../models/subscription.dart';
import 'database_service.dart';

Future<void> seedFromSupabase(DatabaseService db) async {
  final existing = await db.getAllAthletes();
  if (existing.isNotEmpty) return;

  final athletes = [
    Athlete(name: 'Tahir Rayan', phone: '', gender: 'male', startDate: DateTime(2025, 10, 13), notes: 'Importé depuis Supabase PowerGym'),
    Athlete(name: 'ASBAI BEZA', phone: '', gender: 'male', startDate: DateTime(2025, 10, 11), notes: 'Importé depuis Supabase PowerGym'),
    Athlete(name: 'Hidra Masinissa', phone: '', gender: 'male', startDate: DateTime(2025, 10, 11), notes: 'Importé depuis Supabase PowerGym'),
    Athlete(name: 'Hidra Rabia', phone: '', gender: 'male', startDate: DateTime(2025, 10, 11), notes: 'Importé depuis Supabase PowerGym'),
    Athlete(name: 'LAZIBEN ISLAM', phone: '', gender: 'male', startDate: DateTime(2025, 10, 11), notes: 'Importé depuis Supabase PowerGym'),
    Athlete(name: 'Hele Eeee', phone: '', gender: 'female', startDate: DateTime(2025, 10, 11), notes: 'Importé depuis Supabase PowerGym'),
    Athlete(name: 'Iken Nourdine', phone: '', gender: 'male', startDate: DateTime(2025, 10, 11), notes: 'Importé depuis Supabase PowerGym'),
    Athlete(name: 'Khahloul Mazigh', phone: '', gender: 'male', startDate: DateTime(2025, 10, 11), notes: 'Importé depuis Supabase PowerGym'),
    Athlete(name: 'Alloun Aris', phone: '', gender: 'male', startDate: DateTime(2025, 9, 9), notes: 'Abonnement du 09/09/2025'),
    Athlete(name: 'Benchikh Rafik', phone: '', gender: 'male', startDate: DateTime(2025, 10, 11), notes: 'Importé depuis Supabase PowerGym'),
    Athlete(name: 'Kanoun Arbi', phone: '', gender: 'male', startDate: DateTime(2025, 10, 11), notes: 'Importé depuis Supabase PowerGym'),
    Athlete(name: 'Belmezian Seliman', phone: '', gender: 'male', startDate: DateTime(2025, 10, 11), notes: 'Importé depuis Supabase PowerGym'),
    Athlete(name: 'Boulag Islam', phone: '', gender: 'male', startDate: DateTime(2025, 10, 11), notes: 'Importé depuis Supabase PowerGym'),
    Athlete(name: 'Bekouch Yacine', phone: '', gender: 'male', startDate: DateTime(2025, 10, 11), notes: 'Importé depuis Supabase PowerGym'),
    Athlete(name: 'Belahbib Sedik', phone: '', gender: 'male', startDate: DateTime(2025, 10, 11), notes: 'Importé depuis Supabase PowerGym'),
    Athlete(name: 'Benyken Billal', phone: '', gender: 'male', startDate: DateTime(2025, 10, 11), notes: 'Importé depuis Supabase PowerGym'),
    Athlete(name: 'Ait Mezian Seliman', phone: '', gender: 'male', startDate: DateTime(2025, 10, 23), notes: 'Abonnement du 23/10/2025'),
    Athlete(name: 'Amouch Soufiane', phone: '', gender: 'male', startDate: DateTime(2025, 10, 11), notes: 'Importé depuis Supabase PowerGym'),
    Athlete(name: 'Asbai Ariss', phone: '', gender: 'male', startDate: DateTime(2025, 10, 11), notes: 'Importé depuis Supabase PowerGym'),
    Athlete(name: 'Amssis Lyes', phone: '', gender: 'male', startDate: DateTime(2025, 10, 11), notes: 'Importé depuis Supabase PowerGym'),
    Athlete(name: 'Bougharieu Walid', phone: '', gender: 'male', startDate: DateTime(2025, 10, 11), notes: 'Importé depuis Supabase PowerGym'),
    Athlete(name: 'Belmezian Arbi', phone: '', gender: 'male', startDate: DateTime(2025, 10, 11), notes: 'Importé depuis Supabase PowerGym'),
    Athlete(name: 'Djefan Chams adine', phone: '', gender: 'male', startDate: DateTime(2025, 10, 11), notes: 'Importé depuis Supabase PowerGym'),
    Athlete(name: 'Deradj Farouk', phone: '', gender: 'male', startDate: DateTime(2025, 10, 11), notes: 'Importé depuis Supabase PowerGym'),
    Athlete(name: 'Goudjil Oussama', phone: '', gender: 'male', startDate: DateTime(2025, 10, 11), notes: 'Importé depuis Supabase PowerGym'),
    Athlete(name: 'Hadji Naim', phone: '', gender: 'male', startDate: DateTime(2025, 10, 11), notes: 'Importé depuis Supabase PowerGym'),
    Athlete(name: 'Hadji Massi', phone: '', gender: 'male', startDate: DateTime(2025, 10, 11), notes: 'Importé depuis Supabase PowerGym'),
    Athlete(name: 'Hadarbache Farid', phone: '', gender: 'male', startDate: DateTime(2025, 10, 11), notes: 'Importé depuis Supabase PowerGym'),
    Athlete(name: 'Irzi Fares', phone: '', gender: 'male', startDate: DateTime(2025, 10, 11), notes: 'Importé depuis Supabase PowerGym'),
    Athlete(name: 'Kennouche Imane', phone: '', gender: 'male', startDate: DateTime(2025, 10, 11), notes: 'Importé depuis Supabase PowerGym'),
    Athlete(name: 'Benastou Melissa', phone: '', gender: 'female', startDate: DateTime(2025, 10, 11), notes: 'Importé depuis Supabase PowerGym'),
    Athlete(name: 'Tirache Hemza', phone: '', gender: 'male', startDate: DateTime(2025, 10, 11), notes: 'Importé depuis Supabase PowerGym'),
    Athlete(name: 'Belhoul Nadir', phone: '', gender: 'male', startDate: DateTime(2025, 10, 11), notes: 'Importé depuis Supabase PowerGym'),
    Athlete(name: 'Ouaret Massi', phone: '', gender: 'male', startDate: DateTime(2025, 10, 11), notes: 'Importé depuis Supabase PowerGym'),
    Athlete(name: 'Kebane Mayass', phone: '', gender: 'male', startDate: DateTime(2025, 10, 11), notes: 'Importé depuis Supabase PowerGym'),
    Athlete(name: 'Souagui Mounir', phone: '', gender: 'male', startDate: DateTime(2025, 10, 11), notes: 'Importé depuis Supabase PowerGym'),
    Athlete(name: 'Mekniaa Said', phone: '', gender: 'male', startDate: DateTime(2025, 10, 11), notes: 'Importé depuis Supabase PowerGym'),
    Athlete(name: 'Mouhli Walid', phone: '', gender: 'male', startDate: DateTime(2025, 10, 11), notes: 'Importé depuis Supabase PowerGym'),
    Athlete(name: 'Mouhli Yanis', phone: '', gender: 'male', startDate: DateTime(2025, 10, 11), notes: 'Importé depuis Supabase PowerGym'),
    Athlete(name: 'Boulila Juba', phone: '', gender: 'male', startDate: DateTime(2025, 10, 11), notes: 'Importé depuis Supabase PowerGym'),
    Athlete(name: 'Boughanem Youva', phone: '', gender: 'male', startDate: DateTime(2025, 10, 11), notes: 'Importé depuis Supabase PowerGym'),
    Athlete(name: 'Belhaddad Karim', phone: '', gender: 'male', startDate: DateTime(2025, 10, 11), notes: 'Importé depuis Supabase PowerGym'),
    Athlete(name: 'Aksouh Jughurtha', phone: '', gender: 'male', startDate: DateTime(2025, 10, 11), notes: 'Importé depuis Supabase PowerGym'),
    Athlete(name: 'Khenache Samir', phone: '', gender: 'male', startDate: DateTime(2025, 10, 11), notes: 'Importé depuis Supabase PowerGym'),
    Athlete(name: 'Louhab Mazigh', phone: '', gender: 'male', startDate: DateTime(2025, 10, 11), notes: 'Importé depuis Supabase PowerGym'),
    Athlete(name: 'Boulila Koussaila', phone: '', gender: 'male', startDate: DateTime(2025, 10, 11), notes: 'Importé depuis Supabase PowerGym'),
    Athlete(name: 'Chetouh Naima', phone: '', gender: 'female', startDate: DateTime(2025, 10, 11), notes: 'Importé depuis Supabase PowerGym'),
    Athlete(name: 'Oulaarbi Sofiane', phone: '', gender: 'male', startDate: DateTime(2025, 10, 11), notes: 'Importé depuis Supabase PowerGym'),
    Athlete(name: 'Khodja Youris', phone: '', gender: 'male', startDate: DateTime(2025, 10, 11), notes: 'Importé depuis Supabase PowerGym'),
    Athlete(name: 'Gougile Oussama', phone: '', gender: 'male', startDate: DateTime(2025, 10, 11), notes: 'Importé depuis Supabase PowerGym'),
    Athlete(name: 'Boulhouch Rahim', phone: '', gender: 'male', startDate: DateTime(2025, 10, 11), notes: 'Importé depuis Supabase PowerGym'),
    Athlete(name: 'Helaili Wassim', phone: '', gender: 'male', startDate: DateTime(2025, 10, 11), notes: 'Importé depuis Supabase PowerGym'),
    Athlete(name: 'Rabhi Lydia', phone: '', gender: 'female', startDate: DateTime(2025, 10, 11), notes: 'Importé depuis Supabase PowerGym'),
    Athlete(name: 'Belameri Adem', phone: '', gender: 'male', startDate: DateTime(2025, 10, 11), notes: 'Importé depuis Supabase PowerGym'),
    Athlete(name: 'Bouhini Sami', phone: '', gender: 'male', startDate: DateTime(2025, 10, 11), notes: 'Importé depuis Supabase PowerGym'),
    Athlete(name: 'Bouhia Lyes', phone: '', gender: 'male', startDate: DateTime(2025, 10, 11), notes: 'Importé depuis Supabase PowerGym'),
    Athlete(name: 'Biba Amine', phone: '', gender: 'male', startDate: DateTime(2025, 10, 11), notes: 'Importé depuis Supabase PowerGym'),
  ];

  for (final athlete in athletes) {
    final id = await db.insertAthlete(athlete);
    final subscription = Subscription(
      athleteId: id,
      type: SubscriptionType.monthly,
      startDate: athlete.startDate,
      endDate: DateTime(athlete.startDate.year, athlete.startDate.month + 1, athlete.startDate.day),
      price: 3000.0,
      isPaid: true,
      notes: 'Importé depuis Supabase',
    );
    await db.insertSubscription(subscription);
  }
}
