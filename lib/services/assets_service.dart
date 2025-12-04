import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_service.dart';

class AssetsService {
  /// Add a new asset
  static Future<String> addAsset(Map<String, dynamic> assetData) async {
    DocumentReference docRef = await FirebaseService.addDocument(
      'assets',
      assetData,
    );
    return docRef.id;
  }

  /// Get all assets for a user
  static Stream<QuerySnapshot> getUserAssets(String userId) {
    return FirebaseService.queryDocuments(
      'assets',
      field: 'user_id',
      isEqualTo: userId,
    );
  }

  /// Get assets summary for a user
  static Future<Map<String, dynamic>> getAssetsSummary(String userId) async {
    QuerySnapshot snapshot =
        await FirebaseService.queryDocuments(
          'assets',
          field: 'user_id',
          isEqualTo: userId,
        ).first;

    double totalEstimatedValue = 0.0;
    double totalCurrentValue = 0.0;
    double totalDepreciation = 0.0;
    int totalAssets = 0;
    Map<String, double> locationBreakdown = {};

    DateTime now = DateTime.now();

    for (var doc in snapshot.docs) {
      var data = doc.data() as Map<String, dynamic>?;
      if (data != null) {
        double estimatedValue = data['estimated_value'] ?? 0.0;
        double monthlyDepreciation = data['monthly_depreciation'] ?? 0.0;
        String location = data['location'] ?? 'Unknown';
        DateTime? purchaseDate = data['purchase_date']?.toDate();

        totalEstimatedValue += estimatedValue;
        totalAssets++;

        // Calculate depreciation and current value
        int monthsSincePurchase = 0;
        if (purchaseDate != null) {
          monthsSincePurchase =
              ((now.year - purchaseDate.year) * 12 +
                      now.month -
                      purchaseDate.month)
                  .abs();
        }
        double totalDepreciationForAsset =
            monthlyDepreciation * monthsSincePurchase;
        double currentValue = estimatedValue - totalDepreciationForAsset;
        if (currentValue < 0) currentValue = 0;

        totalCurrentValue += currentValue;
        totalDepreciation += totalDepreciationForAsset;
        locationBreakdown[location] =
            (locationBreakdown[location] ?? 0.0) + currentValue;
      }
    }

    return {
      'total_estimated_value': totalEstimatedValue,
      'total_current_value': totalCurrentValue,
      'total_depreciation': totalDepreciation,
      'total_assets': totalAssets,
      'location_breakdown': locationBreakdown,
    };
  }

  /// Update asset
  static Future<void> updateAsset(
    String assetId,
    Map<String, dynamic> assetData,
  ) async {
    await FirebaseService.updateDocument('assets', assetId, assetData);
  }

  /// Delete asset
  static Future<void> deleteAsset(String assetId) async {
    await FirebaseService.deleteDocument('assets', assetId);
  }

  /// Delete asset with confirmation
  static Future<bool> deleteAssetWithConfirmation(String assetId) async {
    try {
      await FirebaseService.deleteDocument('assets', assetId);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get assets by location
  static Stream<QuerySnapshot> getAssetsByLocation(
    String userId,
    String location,
  ) {
    return FirebaseService.queryDocuments(
      'assets',
      field: 'user_id',
      isEqualTo: userId,
    );
  }

  /// Get assets by value range
  static Future<List<Map<String, dynamic>>> getAssetsByValueRange(
    String userId,
    double minValue,
    double maxValue,
  ) async {
    QuerySnapshot snapshot =
        await FirebaseService.queryDocuments(
          'assets',
          field: 'user_id',
          isEqualTo: userId,
        ).first;

    List<Map<String, dynamic>> assets = [];
    DateTime now = DateTime.now();

    for (var doc in snapshot.docs) {
      var data = doc.data() as Map<String, dynamic>?;
      if (data != null) {
        double estimatedValue = data['estimated_value'] ?? 0.0;
        double monthlyDepreciation = data['monthly_depreciation'] ?? 0.0;
        DateTime? purchaseDate = data['purchase_date']?.toDate();

        // Calculate current value
        int monthsSincePurchase = 0;
        if (purchaseDate != null) {
          monthsSincePurchase =
              ((now.year - purchaseDate.year) * 12 +
                      now.month -
                      purchaseDate.month)
                  .abs();
        }
        double totalDepreciation = monthlyDepreciation * monthsSincePurchase;
        double currentValue = estimatedValue - totalDepreciation;
        if (currentValue < 0) currentValue = 0;

        if (currentValue >= minValue && currentValue <= maxValue) {
          assets.add(data);
        }
      }
    }

    return assets;
  }

  /// Get assets by depreciation rate
  static Future<List<Map<String, dynamic>>> getAssetsByDepreciationRate(
    String userId,
    double minDepreciation,
    double maxDepreciation,
  ) async {
    QuerySnapshot snapshot =
        await FirebaseService.queryDocuments(
          'assets',
          field: 'user_id',
          isEqualTo: userId,
        ).first;

    List<Map<String, dynamic>> assets = [];

    for (var doc in snapshot.docs) {
      var data = doc.data() as Map<String, dynamic>?;
      if (data != null) {
        double monthlyDepreciation = data['monthly_depreciation'] ?? 0.0;

        if (monthlyDepreciation >= minDepreciation &&
            monthlyDepreciation <= maxDepreciation) {
          assets.add(data);
        }
      }
    }

    return assets;
  }

  /// Get assets added in date range
  static Future<List<Map<String, dynamic>>> getAssetsInDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    QuerySnapshot snapshot =
        await FirebaseService.queryDocuments(
          'assets',
          field: 'user_id',
          isEqualTo: userId,
        ).first;

    List<Map<String, dynamic>> assets = [];
    for (var doc in snapshot.docs) {
      var data = doc.data() as Map<String, dynamic>?;
      if (data != null) {
        DateTime? dateAdded = data['date_added']?.toDate();
        if (dateAdded != null &&
            dateAdded.isAfter(startDate) &&
            dateAdded.isBefore(endDate)) {
          assets.add(data);
        }
      }
    }

    return assets;
  }

  /// Get total value by location
  static Future<Map<String, double>> getTotalValueByLocation(
    String userId,
  ) async {
    QuerySnapshot snapshot =
        await FirebaseService.queryDocuments(
          'assets',
          field: 'user_id',
          isEqualTo: userId,
        ).first;

    Map<String, double> locationTotals = {};
    DateTime now = DateTime.now();

    for (var doc in snapshot.docs) {
      var data = doc.data() as Map<String, dynamic>?;
      if (data != null) {
        String location = data['location'] ?? 'Unknown';
        double estimatedValue = data['estimated_value'] ?? 0.0;
        double monthlyDepreciation = data['monthly_depreciation'] ?? 0.0;
        DateTime? purchaseDate = data['purchase_date']?.toDate();

        // Calculate current value
        int monthsSincePurchase = 0;
        if (purchaseDate != null) {
          monthsSincePurchase =
              ((now.year - purchaseDate.year) * 12 +
                      now.month -
                      purchaseDate.month)
                  .abs();
        }
        double totalDepreciation = monthlyDepreciation * monthsSincePurchase;
        double currentValue = estimatedValue - totalDepreciation;
        if (currentValue < 0) currentValue = 0;

        locationTotals[location] =
            (locationTotals[location] ?? 0.0) + currentValue;
      }
    }

    return locationTotals;
  }

  /// Get assets with highest depreciation
  static Future<List<Map<String, dynamic>>> getAssetsWithHighestDepreciation(
    String userId,
    int limit,
  ) async {
    QuerySnapshot snapshot =
        await FirebaseService.queryDocuments(
          'assets',
          field: 'user_id',
          isEqualTo: userId,
        ).first;

    List<Map<String, dynamic>> assets = [];
    DateTime now = DateTime.now();

    for (var doc in snapshot.docs) {
      var data = doc.data() as Map<String, dynamic>?;
      if (data != null) {
        double monthlyDepreciation = data['monthly_depreciation'] ?? 0.0;
        DateTime? purchaseDate = data['purchase_date']?.toDate();

        // Calculate total depreciation
        int monthsSincePurchase = 0;
        if (purchaseDate != null) {
          monthsSincePurchase =
              ((now.year - purchaseDate.year) * 12 +
                      now.month -
                      purchaseDate.month)
                  .abs();
        }
        double totalDepreciation = monthlyDepreciation * monthsSincePurchase;

        assets.add({...data, 'total_depreciation': totalDepreciation});
      }
    }

    // Sort by total depreciation (highest first) and limit results
    assets.sort(
      (a, b) => (b['total_depreciation'] ?? 0.0).compareTo(
        a['total_depreciation'] ?? 0.0,
      ),
    );
    return assets.take(limit).toList();
  }

  /// Get assets with lowest current value
  static Future<List<Map<String, dynamic>>> getAssetsWithLowestValue(
    String userId,
    int limit,
  ) async {
    QuerySnapshot snapshot =
        await FirebaseService.queryDocuments(
          'assets',
          field: 'user_id',
          isEqualTo: userId,
        ).first;

    List<Map<String, dynamic>> assets = [];
    DateTime now = DateTime.now();

    for (var doc in snapshot.docs) {
      var data = doc.data() as Map<String, dynamic>?;
      if (data != null) {
        double estimatedValue = data['estimated_value'] ?? 0.0;
        double monthlyDepreciation = data['monthly_depreciation'] ?? 0.0;
        DateTime? purchaseDate = data['purchase_date']?.toDate();

        // Calculate current value
        int monthsSincePurchase = 0;
        if (purchaseDate != null) {
          monthsSincePurchase =
              ((now.year - purchaseDate.year) * 12 +
                      now.month -
                      purchaseDate.month)
                  .abs();
        }
        double totalDepreciation = monthlyDepreciation * monthsSincePurchase;
        double currentValue = estimatedValue - totalDepreciation;
        if (currentValue < 0) currentValue = 0;

        assets.add({...data, 'current_value': currentValue});
      }
    }

    // Sort by current value (lowest first) and limit results
    assets.sort(
      (a, b) =>
          (a['current_value'] ?? 0.0).compareTo(b['current_value'] ?? 0.0),
    );
    return assets.take(limit).toList();
  }
}
