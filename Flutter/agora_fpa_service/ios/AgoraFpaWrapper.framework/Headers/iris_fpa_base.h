//
// Created by CYG on 2021/11/18.
//

#ifndef IRIS_FPA_BASE_H_
#define IRIS_FPA_BASE_H_

#include "iris_base.h"

#ifdef __cplusplus
extern "C" {
#endif

enum ApiTypeProxyService {
  KServiceStart,
  KServiceStop,
  KServiceSetObserver,
  KServiceGetHttpProxyPort,
  KServiceGetTransparentProxyPort,
  KServiceSetParameters,
  KServiceSetOrUpdateHttpProxyChainConfig,
  KServiceGetDiagnosisInfo,
  KServiceGetAgoraFpaProxyServiceSdkVersion,
  KServiceGetAgoraFpaProxyServiceSdkBuildInfo,
};

#ifdef __cplusplus
}
#endif

#endif//IRIS_FPA_BASE_H_