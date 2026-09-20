# 🚗 Rideshare App — iOS

Aplicación móvil de **viajes compartidos para iOS**, desarrollada con **Swift y UIKit**, que simula el flujo principal de una plataforma de transporte bajo demanda.

La aplicación permite al usuario visualizar su ubicación en un mapa, buscar un destino, seleccionar una ruta y solicitar un viaje. También contempla el flujo entre **pasajero y conductor**, incluyendo la solicitud, aceptación, inicio y finalización del viaje.

El proyecto fue desarrollado para practicar el desarrollo de aplicaciones iOS utilizando **UIKit, MapKit, Core Location y Firebase**.

---

## 📱 Vista general

La aplicación está centrada en una experiencia de navegación mediante mapas y en la gestión del ciclo de un viaje.

### Flujo principal

```text
📍 Ubicación actual
       ↓
🔎 Buscar destino
       ↓
📌 Seleccionar destino
       ↓
🗺️ Visualizar ruta
       ↓
🚗 Solicitar viaje
       ↓
👨‍✈️ Conductor acepta
       ↓
🚦 Iniciar viaje
       ↓
🏁 Finalizar viaje
```

---

# ✨ Características

### 🗺️ Mapa y ubicación

* Integración con **Apple Maps mediante MapKit**.
* Obtención de la ubicación actual del usuario.
* Botón para centrar el mapa en la ubicación actual.
* Visualización de pasajeros, conductores y destinos mediante anotaciones.
* Actualización de posiciones mediante coordenadas GPS.
* Visualización de rutas directamente sobre el mapa.

### 🔎 Búsqueda de destinos

* Búsqueda de lugares mediante `MKLocalSearch`.
* Lista de resultados de búsqueda.
* Selección de un destino.
* Colocación de una anotación sobre el destino seleccionado.
* Generación de una ruta entre el punto de origen y destino.

### 🚗 Gestión de viajes

* Solicitud de viajes por parte del pasajero.
* Recepción de solicitudes por parte del conductor.
* Aceptación de viajes.
* Cancelación de viajes.
* Inicio del viaje al llegar al punto de recogida.
* Finalización del viaje al llegar al destino.
* Actualización del estado del conductor durante el viaje.

### 🔥 Firebase

* Autenticación de usuarios.
* Persistencia de información de pasajeros y conductores.
* Almacenamiento de información relacionada con los viajes.
* Actualización de ubicaciones en tiempo real.
* Comunicación entre pasajeros y conductores mediante datos almacenados en Firebase.

### 🎨 Interfaz

* UIKit + Storyboards.
* Auto Layout para diferentes tamaños de pantalla.
* Componentes personalizados.
* Animaciones para mejorar la experiencia de usuario.
* Menú lateral deslizable.
* Pantallas de carga.
* Alertas para informar errores o acciones al usuario.

---

# 🛠️ Tecnologías utilizadas

| Tecnología                     | Uso                                     |
| ------------------------------ | --------------------------------------- |
| **Swift**                      | Lenguaje principal                      |
| **UIKit**                      | Construcción de la interfaz             |
| **Storyboard**                 | Diseño de las pantallas                 |
| **MapKit**                     | Mapas, búsqueda y rutas                 |
| **Core Location**              | Obtención y seguimiento de ubicación    |
| **Firebase Authentication**    | Registro e inicio de sesión             |
| **Firebase Realtime Database** | Datos de usuarios, viajes y ubicaciones |
| **Auto Layout**                | Diseño adaptable                        |
| **Xcode**                      | Entorno de desarrollo                   |

---

# 🏗️ Componentes principales

La aplicación está organizada alrededor de diferentes ViewControllers y componentes especializados.

### `HomeVC`

Pantalla principal de la aplicación.

Se encarga principalmente de:

* Mostrar el mapa.
* Mostrar la ubicación del usuario.
* Buscar destinos.
* Mostrar resultados de búsqueda.
* Mostrar rutas.
* Solicitar viajes.
* Gestionar diferentes estados del viaje.

### `LoginVC`

Pantalla encargada del registro y autenticación de usuarios.

Permite trabajar con diferentes tipos de cuenta:

* Pasajero
* Conductor

### `ContainerVC`

Gestiona el contenedor principal de la aplicación y el **menú lateral deslizable**.

### `PickupVC`

Pantalla utilizada por el conductor cuando recibe una solicitud de viaje.

Permite:

* Visualizar la ubicación del pasajero.
* Aceptar el viaje.
* Cancelar el viaje.
* Iniciar el viaje.
* Continuar hacia el destino.

---

# 📍 MapKit

Uno de los componentes principales del proyecto es **MapKit**.

La aplicación utiliza diferentes funcionalidades de Apple para trabajar con mapas:

```text
MKMapView
    │
    ├── Ubicación del usuario
    │
    ├── DriverAnnotation
    │
    ├── PassengerAnnotation
    │
    ├── DestinationAnnotation
    │
    └── MKPolyline
            │
            └── Ruta del viaje
```

También se utiliza `MKLocalSearch` para encontrar destinos cercanos y `MKDirections` para obtener las rutas entre ubicaciones.

---

# 🔥 Arquitectura de datos

Firebase se utiliza como backend para mantener la información necesaria para el funcionamiento de la aplicación.

```text
              Firebase
                 │
        ┌────────┴────────┐
        │                 │
   Autenticación       Base de datos
        │                 │
        │        ┌────────┼────────┐
        │        │        │        │
      Usuarios  Drivers  Trips   Locations
```

La aplicación utiliza servicios independientes para acceder y actualizar la información, incluyendo un `DataService` para trabajar con la base de datos y un `UpdateService` para actualizar información como la ubicación GPS.

---

# 🚦 Estados del viaje

El botón principal de acción cambia dependiendo del estado actual del viaje.

```text
REQUEST RIDE
     ↓
TRIP REQUESTED
     ↓
TRIP ACCEPTED
     ↓
GET DIRECTIONS
     ↓
START TRIP
     ↓
TRIP IN PROGRESS
     ↓
END TRIP
```

Esto permite que una misma interfaz se adapte al contexto actual del viaje.

---

# 📸 Capturas de pantalla

## 🏠 Pantalla principal

<!-- Agrega aquí la captura de HomeVC -->

![Home Screen](screenshots/home.png)

---

## 🔎 Búsqueda de destino

<!-- Agrega aquí la captura de búsqueda -->

![Destination Search](screenshots/search-destination.png)

---

## 🗺️ Ruta del viaje

<!-- Agrega aquí la captura de la ruta -->

![Trip Route](screenshots/trip-route.png)

---

## 🚗 Solicitud de viaje

<!-- Agrega aquí la captura de Request Ride -->

![Request Ride](screenshots/request-ride.png)

---

## 👨‍✈️ Vista del conductor

<!-- Agrega aquí la captura del conductor -->

![Driver View](screenshots/driver-view.png)

---

## 🚦 Viaje en progreso

<!-- Agrega aquí la captura del viaje -->

![Trip in Progress](screenshots/trip-progress.png)

---

# 📂 Estructura del proyecto

Una estructura aproximada del proyecto es:

```text
Rideshare-App/
│
├── Rideshare-App/
│   │
│   ├── Controllers/
│   │   ├── HomeVC.swift
│   │   ├── LoginVC.swift
│   │   ├── PickupVC.swift
│   │   └── ContainerVC.swift
│   │
│   ├── Views/
│   │   └── Custom Views
│   │
│   ├── Services/
│   │   ├── DataService.swift
│   │   └── UpdateService.swift
│   │
│   ├── Models/
│   │   └── ...
│   │
│   ├── Extensions/
│   │   └── ...
│   │
│   └── Storyboards/
│
├── Rideshare-App.xcodeproj
└── README.md
```

> La estructura puede variar dependiendo de la organización actual del proyecto.

---

# 💻 Requisitos

Antes de ejecutar el proyecto necesitas:

* **macOS**
* **Xcode 15 o superior**
* **iOS 15 o superior**
* Una cuenta de **Firebase**
* Un dispositivo físico o simulador de iOS

---

# ▶️ Instalación

### 1. Clonar el repositorio

```bash
git clone https://github.com/alex-hort/Rideshare-App.git
```

### 2. Entrar al proyecto

```bash
cd Rideshare-App
```

### 3. Abrir el proyecto

```bash
open Rideshare-App.xcodeproj
```

### 4. Configurar Firebase

Agrega tu archivo:

```text
GoogleService-Info.plist
```

al proyecto de Xcode.

> Por seguridad, este archivo no debe subirse al repositorio si contiene la configuración privada de tu proyecto.

### 5. Ejecutar

Selecciona un simulador o dispositivo compatible y presiona:

```text
⌘ + R
```

---

# 🧪 Funcionalidades demostradas

Este proyecto permite practicar conceptos importantes del desarrollo nativo de iOS:

* ViewControllers
* Storyboards
* UIKit
* Auto Layout
* Delegates
* Extensions
* Custom Views
* Animaciones
* MapKit
* MKMapView
* MKLocalSearch
* MKDirections
* Core Location
* GPS
* Annotations
* Polylines
* Firebase Authentication
* Firebase Realtime Database
* Actualización de datos en tiempo real
* Manejo de estados
* UX/UI para aplicaciones móviles

---

# 🎯 Objetivo del proyecto

El objetivo principal de este proyecto es demostrar la implementación de una aplicación iOS de viajes compartidos utilizando tecnologías nativas de Apple y servicios de backend en la nube.

El proyecto pone especial énfasis en el uso de **MapKit, Core Location, UIKit y Firebase** para construir una experiencia completa que conecte el flujo de un pasajero con el de un conductor.

---

# 👨‍💻 Autor

**Alex Hort**

🎓 Computer Engineering Student
📱 iOS / Mobile Developer
☁️ Full-Stack & Cloud Development

GitHub: [@alex-hort](https://github.com/alex-hort)

---

## 📄 Licencia

Este proyecto fue desarrollado con fines educativos y de aprendizaje.

