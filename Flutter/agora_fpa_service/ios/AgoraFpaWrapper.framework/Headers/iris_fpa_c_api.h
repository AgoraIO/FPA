//
// Created by CYG on 2021/11/19.
//

#ifndef IRIS_FPA_C_API_H_
#define IRIS_FPA_C_API_H_

#include "iris_event_handler.h"
#include "iris_fpa_base.h"

typedef void *IrisFpaProxyServicePtr;

/// IrisRtcEngine
IRIS_API IrisFpaProxyServicePtr CreateIrisFpaProxyService();

IRIS_API void DestroyIrisFpaProxyService(IrisFpaProxyServicePtr service_ptr);

IRIS_API IrisEventHandlerHandle SetIrisFpaProxyServiceEventHandler(
    IrisFpaProxyServicePtr service_ptr, IrisCEventHandler *event_handler);

IRIS_API void
UnsetIrisFpaProxyServiceEventHandler(IrisFpaProxyServicePtr service_ptr,
                                     IrisEventHandlerHandle handle);

IRIS_API int CallIrisFpaProxyServiceApi(IrisFpaProxyServicePtr service_ptr,
                                        enum ApiTypeProxyService api_type,
                                        const char *params, char *result);

IRIS_API int CallIrisFpaProxyServiceApiWithBuffer(
    IrisFpaProxyServicePtr service_ptr, enum ApiTypeProxyService api_type,
    const char *params, void *buffer, char *result);

#ifdef __cplusplus
extern "C" {
#endif

#ifdef __cplusplus
}
#endif

#endif//IRIS_FPA_C_API_H_