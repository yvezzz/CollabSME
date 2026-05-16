from rest_framework.views import exception_handler


def custom_exception_handler(exc, context):
    response = exception_handler(exc, context)
    if response is not None:
        detail = response.data
        if isinstance(detail, dict):
            if 'detail' in detail:
                response.data = {'error': detail['detail']}
            elif 'non_field_errors' in detail:
                response.data = {'error': detail['non_field_errors'][0]}
            else:
                first_error = None
                for field, errors in detail.items():
                    if isinstance(errors, list) and errors:
                        first_error = str(errors[0])
                        break
                if first_error:
                    response.data = {'error': first_error}
    return response
