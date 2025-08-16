# Instrucciones

## Resumen
Debes construir un modelo de base de datos que sirva para:

* Soportar una lista de clientes con unos atributos
* Permitir el ingreso de solicitudes de préstamo desde su ingreso hasta su aprobación
* Permitir el ingreso de solicitudes de pagos de estos préstamo desde su ingreso hasta su aprobación
* Soportar los parámetros de negocio, además debes poblar estas tablas de parámetros

## Consideraciones Técnicas Generales
Vas a generar una serie de archivos SQL compatible con Azure SQL, no interesan los demás motores de Base de Datos siempre y cuando cumplan con los criterios establecidos a lo largo de este documento.

Todos los objetos serán en minúsculas y separados con el caracter "_".

Las sentencias culmínalas con ";".

En lo posible te daré los nombres de los objetos y debes respetarlos, en caso no te los de, debes agregarlos tú y deben estar en inglés.

Antes de un CREATE SCHEMA o CREATE TRIGGER, pon una sentencia GO para separar los bloques y no ocasione un error en su ejecución, obviamente si es la primera sentencia del archivo, no pongas el GO.

Todas las fechas y horas deben considerarse en la zona horaria -5 de Lima, Perú.

Todos los campos de las tablas son obligatorios, a no ser que se indique lo contrario.

Si indico un FOREIGN KEY, toma el tipo de dato de la tabla padre.

### Consideraciones para las Tablas
Las tablas tienen un nombre y pertenecen a un esquema.

Asimismo, para efectos de nomenclatura, tienen definido un nemónico, cuyo uso se explica más adelante.

Finalmente tienen un atributo booleano "Trazabilidad", cuyo uso también explico más adelante. Si no indico un valor para Trazabilidad, interpreta que no debe tener Trazabilidad.

### Consideraciones para los Primary Keys
Los Primary Key (PK) deben tener el formato "pk_{nemonico}" donde:
{nemonico} es el nemónico de la tabla

### Consideraciones para los Foreign Keys
Los Foreign Key (FK) deben tener el formato "fk_{nemonico_tabla_padre}_{nemonico_tabla_hija}" donde:
{nemonico_tabla_padre} es el nemónico de la tabla padre
{nemonico_tabla_hija} es el nemónico de la tabla hija, la que recibe el FK

### Consideraciones para las Tablas de Trazabilidad
Si la tabla tiene la indicación "Trazabilidad = Sí"

a) Generar una tabla adicional, en el mismo esquema de la tabla, con el formato "{tabla}_atl" donde:
{tabla} es el nombre de la tabla y sus campos son:
  * atl_written_at    DATETIMEOFFSET(2) : es la fecha y hora en que se dispara el trigger
  * atl_app_name      NVARCHAR(128)     : es la función APP_NAME() de Azure SQL
  * atl_host_name     NVARCHAR(128)     : es la función HOST_NAME() de Azure SQL
  * atl_user          SYSNAME           : es la función CURRENT_USER de Azure SQL
  * atl_action        VARCHAR(3)        : "INS" si es INSERT, "UPD" si es UPDATE, "DEL" si es DELETE
  * y los demás campos de la tabla original. Los campo "atl_" son obligatorios, pero los demás campos son opcionales y sin PRIMARY KEY ni FOREIGN KEY

b) Crear un trigger, en el mismo esquema de la tabla, del tipo "AFTER INSERT, UPDATE, DELETE" con el formato "trg_iud_{tabla}" donde:
{tabla} es el nombre de la tabla
Este trigger se encarga de llevar los datos de la tabla original a la tabla del tipo "atl" indicando especialmente si fue un INS, UPD o DEL

### Campos de auditoría de todas las tablas
Se deben agregar estos campos obligatorios al final de todas las tablas:
* author_id VARCHAR(16)
* written_at DATETIMEOFFSET(2)

Si se va a poblar alguna tabla en forma inicial se debe poner como author_id a "SYSTEM"


## Consideraciones Técnicas Detalladas

### Esquema de Tablas de Parámetros
Nombre: bank_params

#### Tabla de Estados de un Crédito
Nombre: credit_states

Trazabilidad: No

Nemónico: credsta

Campos:
* credit_state_id               VARCHAR(3) PRIMARY KEY
* credit_state_description      VARCHAR(32)

Valores iniciales:
```
PRO, EN PROCESO
APR, APROBADO
DES, DESAPROBADO
```

#### Tabla de Estados de un Pago
Nombre: payment_states

Trazabilidad: No

Nemónico: paysta

Campos:
* payment_state_id               VARCHAR(3) PRIMARY KEY
* payment_state_description      VARCHAR(32)

Valores iniciales:
```
PRO, EN PROCESO
APR, APROBADO
DES, DESAPROBADO
```

#### Tabla de Tipos de Cliente
Nombre: client_types

Trazabilidad: No

Nemónico: clityp

Campos:
* client_type_id               VARCHAR(3) PRIMARY KEY
* client_type_description      VARCHAR(32)

Valores iniciales:
```
MIC, MICRO EMPRESA
PEQ, PEQUEÑA EMPRESA
MED, MEDIANA EMPRESA
GRA, GRAN EMPRESA
```

#### Tabla de Categoría de Riesgo de Cliente
Nombre: risk_categories

Trazabilidad: No

Nemónico: rskcat

Campos:
* risk_category_id          VARCHAR(2) PRIMARY KEY
* risk_category_description VARCHAR(32)

Valores iniciales:
```
NO, NORMAL
PP, PROBLEMA POTENCIAL
DE, DEFICIENTE
DU, DUDOSO
PE, PÉRDIDA
```

### Esquema de Tablas de Negocio
bank

#### Tabla de Clientes
Nombre: client

Trazabilidad: Sí

Nemónico: cli

Campos:
* client_id                     VARCHAR(16) PRIMARY KEY
* client_name                   VARCHAR(256)
* client_type_id                FOREIGN KEY con client_types
* risk_category_id              FOREIGN KEY con risk_categories
* credit_line_authorized_amount NUMERIC(15, 2)
* credit_line_used_amount       NUMERIC(15, 2)


#### Tabla de Solicitudes de Crédito 
Nombre: credit_orders

Trazabilidad: Sí

Nemónico: creord

Campos:
* credit_order_id               INT IDENTITY PRIMARY KEY
* client_id                     FOREIGN KEY con client
* amount                        NUMERIC(15, 2)
* interest_rate                 NUMERIC(5, 2)
* due_date                      DATE
* client_type_id                FOREIGN KEY con client_types, es la foto de cuando se INSERTa el registro, según client
* risk_category_id              FOREIGN KEY con risk_categories, es la foto de cuando se INSERTa el registro, según client
* credit_line_authorized_amount NUMERIC(15, 2), es la foto de cuando se INSERTa el registro, según client
* credit_line_used_amount       NUMERIC(15, 2), es la foto de cuando se INSERTa el registro, según client
* credit_state_id               FOREIGN KEY con credit_states

#### Tabla de Solicitudes de Pagos de Créditos
Nombre: payment_orders

Trazabilidad: Sí

Nemónico: payord

Campos:
* credit_order_id               INT FOREIGN KEY con credit_orders
* payment_sequence              SMALLINT, correlativo de pagos del respectivo credit_order_id, es decir, con cada credit_order_id empieza de 1 y va aumentando a medida que haga más pagos
* amount                        NUMERIC(15, 2), monto pagado
* paymen_state_id               FOREIGN KEY con payment_states

### Data de Prueba
Al final genérame data de prueba para las tablas del esquema bank con las siguientes características:

### Tabla de Clientes
Genera 1000 clientes
* client_id : con la forma de RUC de empresas peruanas, parecidas, no iguales para evitar problemas legales. Que no existan duplicados en toda la tabla.
* client_name :
  * Es extremadamente importante que te asegures que el client_name sea único en toda la tabla
  * Puedes usar un formato como Tipo de Empresa + Nombre Aleatorio + Tipo de Sociedad donde:
    * Tipo de Empresa: Puede ser Asociación, Sociedad, Empresa, Industrias u otros similares
    * Nombre Aleatorio: 
      * Puedes usar los rubros más comunes en Perú
      * Puedes usar nombres de:
        * Todos los santos peruanos
        * 10 provincias y 20 distritos del Perú
        * 15 playas del Perú
        * 10 minerales que exporte el Perú
        * 15 peces más pescados en Perú
        * Todos los nombres de Papas de la Edad Media
        * 20 nombres de países y capitales de África y Oceanía
        * Puedes combinarlos en aras de tratar de no repetir los nombres como "Empresa Oro y El Cairo SA"
    * Tipos de Sociedad: Pueden ser (SA, SAC, EIRL y otros dos comunes en Perú)
* client_type_id: el 5% GRA, el 25% MED, el 40% PEQ y el 30% MIC
* risk_category_id :
  * en caso de GRA (80% NO, 10% PP, 05% DE, 03% DU, 02% PE)
  * en caso de MED (70% NO, 15% PP, 10% DE, 01% DU, 04% PE)
  * en caso de PEQ (50% NO, 30% PP, 05% DE, 05% DU, 10% PE)
  * en caso de MIC (20% NO, 40% PP, 20% DE, 10% DU, 10% PE) 
* credit_line_authorized_amount : montos que acaben en 000.00 (es decir, centenas, decenas y unidades en cero, así como la parte decimal también en cero) y variando aleatoriamente entre: 
  * en caso de GRA (entre 12,000,000 y 50,000,000)
  * en caso de MED (entre 9,000,000 y 12,000,000)
  * en caso de PEQ (entre 800,000 y 9,000,000)
  * en caso de MIC (entre 10,000 y 800,000)
* credit_line_used_amount : montos que esten entre 0.00 (valor absoluto) y 5% más del credit_line_authorized_amount para ese cliente
* written_at: Pon una fecha entre tres años y dos años atrás partiendo de hoy

### Tabla de Solicitudes de Crédito y de Pagos
Vas a simular una secuencia de solicitudes de crédito así como sus pagos junto con la evoluición de su línea de crédito.

Partiendo de la data generada en la tabla de clientes:
* Crea una solicitud de crédito en estado EN PROCESO:
  * written_at: una fecha entre la fecha del último crédito generado de este cliente y hoy, que no sea sábado ni domingo, ni feriados de Perú
  * due_date: una fecha entre written_at y hoy, que no sea sábado ni domingo, ni feriados de Perú
* Actualizas la solicitud de crédito en:
  * estado APROBADO, debes actualizar el monto disponible de la línea del cliente pues esta se reduce al aprobarse el crédito
  * estado DESAPROBADO, no actualices el monto disponible de la línea del cliente
  * actualizas la fecha en que hiciste este cambio de estado en la solicitud de crédito
  * actualizas la fecha en que hiciste este cambio de línea disponible del cliente de ser el caso
* Crea una solicitud de pago del crédito mediante:
  * la secuencia es un correlativo de pago para este crédito, empieza de 1 y aumenta ascendentemente de 1 en 1
  * written_at: una fecha entre la fecha de aprobación del crédito que estás pagando y hoy
  * el monto a pagar debe ser igual que el monto del crédito (capital), más los intereses compuestos generados, tomando:
    * fecha de inicio del cálculo: la fecha de aprobación del crédito que estamos pagando
    * días transcurridos: hoy 
  * se crea con estado EN PROCESO
* Actualiza la solicitud de pago mediante:
  * estado APROBADO, debes actualizar el monto disponible de la línea del cliente pues esta aumenta dado que ya pagó parte o el total del crédido
  * estado DESAPROBADO, no actualices el monto disponible de la línea del cliente
  * actualizas la fecha en que hiciste este cambio de estado en la solicitud de pago del crédito
  * actualizas la fecha en que hiciste este cambio de línea disponible del cliente de ser el caso

Genera por cada cliente la siguiente cantidad de créditos:
  * en caso de GRA (entre 0 y 100)
  * en caso de MED (entre 0 y 50)
  * en caso de PEQ (entre 0 y 10)
  * en caso de MIC (entre 0 y 3)
* credit_order_id : no lo tomes en cuenta, pues es un IDENTITY
* client_id : el client_id de la tabla cliente
* credit_state_id: 
    * en caso de GRA (90% Aprobados, 02% Desaprobados, 08% En Proceso)
    * en caso de MED (80% Aprobados, 10% Desaprobados, 10% En Proceso)
    * en caso de PEQ (50% Aprobados, 20% Desaprobados, 30% En Proceso)
    * en caso de MIC (50% Aprobados, 30% Desaprobados, 20% En Proceso)
* * amount :
  * acá quiero simular que el cliente pide créditos a lo largo del tiempo, el banco le asigna una línea de crédito (credit_line_authorized_amount)
  * obviamente el cliente empieza con un credit_line_used_amount de CERO pero a medida que el banco le aprueba créditos este monto debe aumentar. No tomar en cuenta los desaprobados o en proceso.
  * es decir debe simular que el cliente está pidiendo créditos y estos han sido aprobados de modo que va consumiendo la línea del cliente hasta llegar al monto indicado en la tabla cliente
* interest_rate : 
    * en caso de GRA (entre 0.5 y 3)
    * en caso de MED (entre 3 y 7)
    * en caso de PEQ (entre 5 y 10)
    * en caso de MIC (entre 10 y 30)
* written_at : es la fecha en que pidió el crédito, desde dos años atrás hasta un mes atrás. ten en cuenta el orden de las fechas y los montos para que parezca que el cliente va pidiendo créditos en forma ordenada y va aumentando el monto usado en esta tabla
* due_date : entre hoy y dos años atrás, solo considera de lunes a viernes y no tomes en cuenta los feriados peruanos
* client_type_id : el client_type_id de la tabla cliente 
* risk_category_id : el risk_category_id de la tabla cliente
* credit_line_authorized_amount : el credit_line_authorized_amount de la tabla cliente 
* credit_line_used_amount : es el monto usado de la línea, es decir según los créditos aprobados del cliente, empieza de cero y termina igual al credit_line_used_amount de la tabla cliente 
 
# Archivos esperados
## drop-objects.sql
Con las sentencias para eliminar todos los objetos previos a la ejecución de este script. Validando previamente si existen o no

## create-objects.sql
Con las sentencias para la creación ordenada y lógica de schemas, tablas, triggers

## insert-params.sql
Con las sentencias para poblar las tablas del esquema bank_params

## drop-test-data.sql
Con las sentencias para eliminar ordenada y lógicamente la data de las tablas del esquema bank

## insert-clients-test-data.sql
Con las sentencias para poblar la data de clients según las reglas indicadas

## insert-credit-orders-test-data.sql
Con las sentencias para poblar la data de clients según las reglas indicadas