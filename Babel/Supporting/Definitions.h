//
//  Definitions.h
//  Babel
//
//  Created by Renzo Crisostomo on 23/07/14.
//  Copyright (c) 2014 Renzo Crisóstomo. All rights reserved.
//

#ifndef Babel_Definitions_h
#define Babel_Definitions_h

typedef NS_ENUM(NSInteger, BABErrorCode) {
    BABErrorCodeFailedAuthorization = 99999,
    BABErrorCodeFailedRequest,
    BABErrorCodeFileNotFound,
    BABErrorCodeRateLimitReached,
    BABErrorCodeSringDecodingFailed
};

typedef NS_ENUM(NSInteger, BABDifficultyMode) {
    BABDifficultyModeEasy,
    BABDifficultyModeNormal,
    BABDifficultyModeHard,
    BABDifficultyModeNone
};

static int const ddLogLevel = LOG_LEVEL_VERBOSE;

#endif
