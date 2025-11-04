#include <iostream>
#include <libusb.h>
#include <cstring>

const char* getDeviceClassName(uint8_t class_code) {
    switch (class_code) {
        case 0x00: return "Не указан";
        case 0x01: return "Аудиоустройство";
        case 0x02: return "Коммуникационное устройство (CDC)";
        case 0x03: return "Устройство пользовательского интерфейса (HID)";
        case 0x05: return "Физическое устройство";
        case 0x06: return "Изображения";
        case 0x07: return "Принтер";
        case 0x08: return "Устройство хранения данных";
        case 0x09: return "Концентратор (Hub)";
        case 0x0A: return "CDC-Data";
        case 0x0B: return "Smart Card";
        case 0x0D: return "Content Security";
        case 0x0E: return "Видеоустройство";
        case 0x0F: return "Персональное медицинское устройство";
        case 0x10: return "Аудио/видеоустройства (AV)";
        case 0xDC: return "Диагностическое устройство";
        case 0xE0: return "Беспроводной контроллер";
        case 0xEF: return "Различные устройства (Miscellaneous)";
        case 0xFE: return "Специфическое устройство (Application Specific)";
        default:   return "Неизвестный класс";
    }
}

void printSerialNumber(libusb_device* dev, const libusb_device_descriptor* desc) {
    if (desc->iSerialNumber == 0) {
        std::cout << "  Серийный номер: не задан\n";
        return;
    }

    libusb_device_handle* handle = nullptr;
    int r = libusb_open(dev, &handle);
    if (r != LIBUSB_SUCCESS || !handle) {
        std::cerr << "  Серийный номер: недоступен (ошибка открытия: "
                  << libusb_error_name(r) << ")\n";
        return;
    }

    unsigned char serial[256] = {0};
    r = libusb_get_string_descriptor_ascii(handle, desc->iSerialNumber, serial, sizeof(serial));
    if (r > 0) {
        std::cout << "  Серийный номер: " << serial << "\n";
    } else {
        std::cerr << "  Серийный номер: недоступен (ошибка чтения: "
                  << libusb_error_name(r) << ")\n";
    }

    libusb_close(handle);
}

void printDeviceInfo(libusb_device* dev) {
    libusb_device_descriptor desc{};
    int r = libusb_get_device_descriptor(dev, &desc);
    if (r < 0) {
        std::cerr << "Ошибка: не удалось получить дескриптор устройства.\n";
        return;
    }

    std::cout << "Класс: 0x" << std::hex << static_cast<int>(desc.bDeviceClass)
              << " (" << getDeviceClassName(desc.bDeviceClass) << ")\n";
    std::cout << "Vendor ID: 0x" << std::hex << desc.idVendor << "\n";
    std::cout << "Product ID: 0x" << std::hex << desc.idProduct << "\n";

    printSerialNumber(dev, &desc);
    std::cout << "----------------------------------------\n";
}

int main() {
    libusb_context* ctx = nullptr;
    libusb_device** devs = nullptr;
    int r = libusb_init(&ctx);
    if (r < 0) {
        std::cerr << "Ошибка инициализации libusb: " << libusb_error_name(r) << "\n";
        return 1;
    }

    // Установка уровня логирования 
    #if defined(LIBUSB_API_VERSION) && (LIBUSB_API_VERSION >= 0x01000106)
        libusb_set_option(ctx, LIBUSB_OPTION_LOG_LEVEL, 3);
    #else
        libusb_set_debug(ctx, 3);
    #endif

    ssize_t cnt = libusb_get_device_list(ctx, &devs);
    if (cnt < 0) {
        std::cerr << "Ошибка получения списка устройств: " << libusb_error_name(cnt) << "\n";
        libusb_exit(ctx);
        return 1;
    }

    std::cout << "Найдено USB-устройств: " << cnt << "\n";
    std::cout << "========================================\n";

    for (ssize_t i = 0; i < cnt; ++i) {
        printDeviceInfo(devs[i]);
    }

    libusb_free_device_list(devs, 1);
    libusb_exit(ctx);
    return 0;
}