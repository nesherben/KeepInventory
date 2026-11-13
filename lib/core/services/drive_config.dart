/// Configuración de Google Drive.
///
/// Para activar la copia en Drive hay que crear en Google Cloud Console:
///  1. Un proyecto con la "Google Drive API" activada.
///  2. Un cliente OAuth de tipo **Android** (paquete `com.example.keepinventory`
///     y el SHA-1 del keystore de debug Y del de release).
///  3. Un cliente OAuth de tipo **Web**: su ID es el [driveServerClientId].
///  4. La pantalla de consentimiento con el alcance `drive.appdata` (no es
///     sensible) y tu cuenta como usuario de prueba.
///
/// Los ID de cliente no son secretos. Mientras [driveServerClientId] esté
/// vacío, la app muestra Drive como "pendiente de configurar".
const driveServerClientId =
    '985036353563-ebf5reh9lehuiug62jhr7u62224g68b5.apps.googleusercontent.com';

/// Alcance: carpeta oculta y privada de la app dentro del Drive del usuario.
/// No da acceso al resto de archivos.
const driveAppDataScope = 'https://www.googleapis.com/auth/drive.appdata';
