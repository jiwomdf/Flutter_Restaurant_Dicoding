import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:fundamental_beginner_restourant/domain/data/local/db_service.dart';
import 'package:fundamental_beginner_restourant/domain/data/local/entity/restaurant_entity.dart';
import 'package:fundamental_beginner_restourant/features/main/restaurant_db_provider.dart';
import 'package:provider/provider.dart';
import '../../domain/data/api/response/restaurant_detail_element.dart';
import 'detail_restaurant_provider.dart';
import '../../domain/data/api/api_service.dart';
import '../../util/state/ResultState.dart';
import '../../util/stringutil/string_util.dart';


class DetailScreen extends StatelessWidget {

  static const routeName = '/detail_screen';
  static const String navigatorCallback = "navigator_callback_value";

  final String id;

  const DetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider<DetailRestaurantProvider>(
              create: (_) {
                return DetailRestaurantProvider(id: id, apiService: ApiService());
              }
          ),
          ChangeNotifierProvider<RestaurantDbProvider?>(
              create: (_) {
                var dbProvider = RestaurantDbProvider(dbService: DbService());
                dbProvider.getIsRestaurantFav(id);
                return dbProvider;
              }
          )
        ],
      child: _detailScreenState(context),
    );
  }

  Widget _detailScreenState(BuildContext buildContext){
    return Consumer<DetailRestaurantProvider>(builder: (context, state, _) {
      if (state.state == ResultState.loading) {
        return const Center(child: CircularProgressIndicator());
      } else if (state.state == ResultState.hasData) {
        return PopScope(
          canPop: false,
          onPopInvoked: (didPop) async {
            Navigator.of(context).pop(DetailScreen.navigatorCallback);
          },
          child: Scaffold(
              appBar: AppBar(
                backgroundColor: Theme.of(buildContext).colorScheme.inversePrimary,
                title: Text(state.result.restaurant?.name ?? "-"),
              ),
              body: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _successDetailScreen(state.result),
              )
          )
        );
      } else if (state.state == ResultState.noData) {
        return const Center(child: CircularProgressIndicator());
      } else if (state.state == ResultState.error) {
        return const Center(child: Material(child: Text("There is no internet connection")));
      } else {
        return const Center(child: Material(child: Text('')));
      }
    });
  }

  Widget _successDetailScreen(RestaurantDetailElement result) {
    return Consumer<RestaurantDbProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    SizedBox(
                        width: MediaQuery.of(context).size.width,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(10.0),
                              bottomRight: Radius.circular(10.0)),
                          child: CachedNetworkImage(
                              imageUrl: "${StringUtil.imgMediumUrl}${result.restaurant?.pictureId ?? ""}",
                              placeholder: (context, url) => const CircularProgressIndicator(),
                              errorWidget: (context, url, error) => const Icon(Icons.error)),
                        )),
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: FloatingActionButton.small(
                          shape: const CircleBorder(),
                          backgroundColor: getFavoriteBgColor(provider?.isFavRestaurants ?? false),
                          onPressed: () => {
                            if(provider?.isFavRestaurants ?? false) {
                              provider.removeFavRestaurant(id: result.restaurant?.id ?? "")
                            } else {
                              provider.insertFavRestaurant(RestaurantEntity(
                                  id: result.restaurant?.id ?? "",
                                  name: result.restaurant?.name ?? "",
                                  description: result.restaurant?.description ?? "",
                                  city: result.restaurant?.city ?? "",
                                  address: result.restaurant?.address ?? "",
                                  pictureId: result.restaurant?.pictureId ?? "",
                                  rating: result.restaurant?.rating ?? 0
                              ))
                            }
                          },
                          child: const Icon(Icons.star, color: Colors.white)),
                    )
                  ],
                ),
                const Padding(
                    padding: EdgeInsets.only(left: 8, top: 16),
                    child: Text("Location")),
                Padding(
                    padding: const EdgeInsets.only(left: 8, top: 2),
                    child: Text(result.restaurant?.city ?? "",
                        style: const TextStyle(
                            wordSpacing: 2, fontWeight: FontWeight.bold))),
                const Padding(
                    padding: EdgeInsets.only(left: 8, top: 16),
                    child: Text("Rating")),
                Padding(
                    padding: const EdgeInsets.only(left: 4, top: 2),
                    child: Row(
                      children: [
                        const Icon(Icons.star_rate_rounded),
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Text((result.restaurant?.rating ?? "").toString(),
                              style: const TextStyle(
                                  wordSpacing: 2, fontWeight: FontWeight.bold)),
                        )
                      ],
                    )),
                const Padding(
                    padding: EdgeInsets.only(left: 8, top: 16), child: Text("Foods")),
                Padding(
                    padding: const EdgeInsets.only(left: 8, top: 4),
                    child: SizedBox(
                        height: 50,
                        child: ListView.builder(
                            itemCount: result.restaurant?.menus.foods.length ?? 0,
                            scrollDirection: Axis.horizontal,
                            itemBuilder: (context, index) {
                              final foods = result.restaurant?.menus.foods[index];
                              return Padding(
                                  padding: const EdgeInsets.only(left: 2, right: 2),
                                  child: Chip(label: Text(foods?.name ?? "-")));
                            }))),
                const Padding(
                    padding: EdgeInsets.only(left: 8, top: 8), child: Text("Drinks")),
                Padding(
                    padding: const EdgeInsets.only(left: 8, top: 4),
                    child: SizedBox(
                      height: 50,
                      child: ListView.builder(
                          itemCount: result.restaurant?.menus.drinks.length ?? 0,
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (context, index) {
                            final drink = result.restaurant?.menus.drinks[index];
                            return Padding(
                                padding: const EdgeInsets.only(left: 2, right: 2),
                                child: Chip(label: Text(drink?.name ?? "")));
                          }),
                    )),
                Padding(
                    padding: const EdgeInsets.only(left: 8, top: 16),
                    child: Text(result.restaurant?.description ?? ""))
              ],
            ),
          );
        }
    );
  }

  Color getFavoriteBgColor(bool isFavorite) {
    if(isFavorite)  {
      return Colors.redAccent;
    } else {
      return Colors.black;
    }
  }
}
