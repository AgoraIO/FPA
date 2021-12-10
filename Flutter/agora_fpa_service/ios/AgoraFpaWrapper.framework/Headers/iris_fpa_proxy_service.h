//
// Created by CYG on 2021/11/18.
//

#ifndef IRIS_FPA_PROXY_SERVICE_H_
#define IRIS_FPA_PROXY_SERVICE_H_

#include "iris_event_handler.h"
#include "iris_fpa_base.h"

namespace agora {
namespace iris {
namespace fpa {
class IrisFpaProxyServiceImpl;

class IRIS_CPP_API IrisFpaProxyService {
 public:
  explicit IrisFpaProxyService(IrisFpaProxyServiceImpl *impl = nullptr);
  virtual ~IrisFpaProxyService();

  void SetEventHandler(IrisEventHandler *event_handler);

  int CallApi(ApiTypeProxyService api_type, const char *params,
              char result[kBasicResultLength]);

  int CallApi(ApiTypeProxyService api_type, const char *params, void *buffer,
              char result[kBasicResultLength]);

 private:
  IrisFpaProxyServiceImpl *impl_;
};

}// namespace fpa
}// namespace iris
}// namespace agora

#endif//IRIS_FPA_PROXY_SERVICE_H_