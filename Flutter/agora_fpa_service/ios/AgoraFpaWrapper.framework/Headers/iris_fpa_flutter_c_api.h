#include "iris_fpa_c_api.h"
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

IRIS_API IrisEventHandlerHandle SetIrisFpaProxyServiceEventHandlerFlutter(
    IrisFpaProxyServicePtr service_ptr, void *init_dart_api_data,
    int64_t dart_send_port);

#ifdef __cplusplus
}
#endif