import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:fluxtube/domain/core/failure/main_failure.dart';
import 'package:fluxtube/domain/watch/models/comments/comments_resp.dart';
import 'package:fluxtube/domain/watch/models/video/watch_resp.dart';
import 'package:fluxtube/domain/watch/watch_service.dart';
import 'package:injectable/injectable.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../../domain/core/api_end_points.dart';

@LazySingleton(as: WatchService)
class WatchImpliment implements WatchService {
  //get video informations
  @override
  Future<Either<MainFailure, WatchResp>> getVideoData(
      {required String id}) async {
    try {
      final Response response =
          await Dio(BaseOptions()).get(ApiEndPoints.watch + id);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final WatchResp result = WatchResp.fromJson(response.data);

        return Right(result);
      } else {
        return const Left(MainFailure.serverFailure());
      }
    } catch (_) {
      return const Left(MainFailure.clientFailure());
    }
  }

//get comments
  @override
  Future<Either<MainFailure, CommentsResp>> getCommentsData(
      {required String id}) async {
    try {
      final Response response =
          await Dio(BaseOptions()).get(ApiEndPoints.comments + id);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final CommentsResp result = CommentsResp.fromJson(response.data);

        return Right(result);
      } else {
        return const Left(MainFailure.serverFailure());
      }
    } catch (_) {
      return const Left(MainFailure.clientFailure());
    }
  }

  @override
  Future<Either<MainFailure, CommentsResp>> getCommentRepliesData(
      {required String id, required String repliesPage}) async {
    try {
      final Response response = await Dio(BaseOptions())
          .get('${ApiEndPoints.commentReplies}$id/?nextpage=$repliesPage');
      if (response.statusCode == 200 || response.statusCode == 201) {
        final CommentsResp result = CommentsResp.fromJson(response.data);

        return Right(result);
      } else {
        return const Left(MainFailure.serverFailure());
      }
    } catch (_) {
      return const Left(MainFailure.clientFailure());
    }
  }

// get paged (more) commens/replied comments
  @override
  Future<Either<MainFailure, CommentsResp>> getMoreCommentsData(
      {required String id, String? nextPage}) async {
    try {
      final Response response = await Dio(BaseOptions())
          .get('${ApiEndPoints.commentReplies}$id/?nextpage=$nextPage');
      if (response.statusCode == 200 || response.statusCode == 201) {
        final CommentsResp result = CommentsResp.fromJson(response.data);
        return Right(result);
      } else {
        return const Left(MainFailure.serverFailure());
      }
    } catch (e) {
      return const Left(MainFailure.clientFailure());
    }
  }

  @override
  Future<Either<MainFailure, List<Map<String, String>>>> getSubtitles(
      {required String id}) async {
    try {
      var yt = YoutubeExplode();
      var manifest = await yt.videos.closedCaptions.getManifest(id);

      // Filter tracks to get only those with type 'vtt'
      var vttTracks = manifest.tracks
          .where((track) => track.format.formatCode == 'vtt')
          .toList();

      // Create a list with code, name, and type
      var vttTrackInfo = vttTracks
          .map((track) => {
                'code': track.language.code,
                'name': track.language.name,
                'url': track.url.toString()
              })
          .toList();

      // Close the YoutubeExplode instance
      yt.close();

      return Right(vttTrackInfo);
    } catch (e) {
      return const Left(MainFailure.clientFailure());
    }
  }
}
