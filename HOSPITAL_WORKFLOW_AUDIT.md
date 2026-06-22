# MediHub Hospital Workflow Audit

Ngay lap: 07/06/2026

## Ket luan ngan

MediHub Admin khong nen van hanh nhu CMS chung. He thong can di theo chuoi nghiep vu benh vien: tiep nhan -> kham -> chi dinh -> ket qua -> thanh toan -> thong bao/ho so.

Trang Admin hien tai da co UI dep, co API that cho nhieu bang va da co selector quan he cho benh nhan/khoa/bac si o mot so form. Tuy nhien nhieu module van con nam o dang CRUD tong quat, status chua duoc chuan hoa theo nghiep vu, va mot so bang van luu text tam thoi thay vi quan he den danh muc.

## Bang danh gia module

| Module | Hien trang | Van de chinh | Huong xu ly |
| --- | --- | --- | --- |
| Dashboard | Truoc do chu yeu la tong so | Giong dashboard CMS, thieu hang doi van hanh | Da bo sung nhom operations: lich hen hom nay, so thu tu, xet nghiem, CDHA, phau thuat, vien phi |
| Lich hen | Da co REQUESTED/PROPOSED/CONFIRMED/COMPLETED/CANCELLED | Thieu CHECKED_IN/IN_PROGRESS, admin bam hoan tat truc tiep tu CONFIRMED | Da bo sung tiep nhan va bat dau kham truoc khi hoan tat |
| Ho so kham | Chi co MedicalRecord don gian: diagnosis/conclusion/note | Chua du la phien kham: ly do, benh su, trieu chung, ICD10, huong dieu tri, tai kham | Can nang schema MedicalRecord o pha 3 |
| Xet nghiem | Co LabResult va chi so | Chua la quy trinh chi dinh -> lay mau -> xu ly -> duyet; status mau chua dong bo | Chuan hoa workflow va lien ket chi dinh tu phien kham |
| CDHA | Co ImagingResult | Chua co workflow chi dinh/ket qua/duyet ro rang | Chuan hoa workflow va lien ket tu phien kham |
| Don thuoc | Co Prescription va PrescriptionItem | Con gan theo text benh nhan/bac si o vai truong; chua gan danh muc thuoc day du | Chuyen sang chon tu danh muc thuoc, sinh tu phien kham |
| Vien phi | Co Billing va PatientServiceUsage | Chua day du luong tao phi tu kham/chi dinh/thuoc/phau thuat | Chuan hoa thu tu phat sinh phi va thanh toan |
| Phau thuat/thu thuat | Co SurgeryCase va SurgeryTimeline | Co timeline nhung status/chi tiet chua dong bo nhu quy trinh mo | Nang thanh workflow len lich -> vao phong -> dang mo -> hoi tinh -> hoan tat |
| Tin tuc | CMS-like la chap nhan duoc | Khong phai nghiep vu kham | Giu module CMS, chi can UI/encoding tot |
| Thong bao | Co Notification | Can draft/sent, tap nguoi nhan, gan workflow | Tach thong bao he thong va thong bao nghiep vu |
| Mobile | Da co request/confirm lich hen | Can hien thi status moi va thong tin de xuat/ket qua ro hon | Cap nhat sau khi backend/admin on dinh |

## Cac diem can bo schema sau

- Appointment nen luu `departmentId`, `doctorId`, `proposedAt`, `checkedInAt`, `startedAt`, `completedAt` va timeline status rieng.
- MedicalRecord can la phien kham day du: reason, history, symptoms, vital signs, preliminary diagnosis, ICD10, conclusion, treatment, instructions, follow-up.
- Lab/Imaging/Prescription/Billing/Surgery nen duoc tao tu MedicalRecord hoac order table, khong chi CRUD doc lap.
- Cac truong text tam thoi nhu `doctorName`, `department`, `patient` can duoc giu de tuong thich nhung bo sung relation that.

## Pha uu tien

1. Pha 1: Audit va ghi file nay.
2. Pha 2: Dashboard + Appointment workflow.
3. Pha 3: MedicalRecord + Lab + Imaging.
4. Pha 4: Prescription + Billing.
5. Pha 5: Surgery.
6. Pha 6: News + Notification + sua encoding UI.
7. Pha 7: Test day du backend/admin/mobile.

## Viec da bat dau trong pha 2

- Backend appointment them status `CHECKED_IN` va `IN_PROGRESS`.
- Backend them API check-in va start appointment cho mobile/admin neu can.
- Admin appointment action doi sang chuoi: de xuat -> tiep nhan -> bat dau kham -> hoan tat.
- Dashboard backend tra them `operations`.
- Dashboard admin hien thi cac nhom van hanh thay vi chi la tong so.
- Admin sidebar da doi sang nhom MediHub HIS: van hanh kham benh, can lam sang, tai chinh, ho so, cham soc, quan tri.
- Cac module nghiep vu chinh da doi tu bang CRUD sang workbench: danh sach xu ly ben trai, ho so/action ben phai, loc nhanh theo trang thai.
- Lich hen admin da dung nut co chu thay vi icon nho de giam thao tac va de nhin ro buoc tiep theo.
- Trong chi tiet lich hen da them khong gian kham benh: bac si co the chi dinh xet nghiem, CDHA, dich vu, ke don, tao vien phi va xem cac ket qua lien quan ngay tren phien kham.
- Cac chi dinh tu phien kham duoc tao thanh record that trong module chuyen mon tuong ung de ky thuat vien/bac si chuyen khoa xu ly tiep.
- Da them phieu chi dinh dang preview de in/dua benh nhan di lam CLS trong qua trinh kham.

## Viec da lam trong pha schema HIS

- Da them `MedicalEncounter` lam phien kham trung tam, lien ket voi benh nhan, lich hen, khoa, bac si, sinh hieu, chi dinh, ket qua, don thuoc, phau thuat va vien phi.
- Da them `ClinicalOrder` va `ClinicalOrderEvent` de chuan hoa luong chi dinh: xet nghiem, CDHA, dich vu ky thuat, don thuoc, phau thuat. Moi chi dinh co ma phieu, loai chi dinh, trang thai, khoa, bac si chi dinh va so tien du kien.
- Da them `BillingItem` de tach chi tiet phat sinh vien phi khoi bang tong `Billing`. Khi bac si chi dinh dich vu/CLS hoac tao vien phi, he thong sinh dong vien phi chi tiet.
- Da bo sung khoa ngoai/chi muc tu `Appointment`, `LabResult`, `ImagingResult`, `Prescription`, `SurgeryCase`, `PatientServiceUsage`, `Billing` ve `MedicalEncounter` va `ClinicalOrder`.
- Backend admin khi tao chi dinh tu phien kham se tu tao encounter neu lich hen chua co, tao clinical order, tao billing item neu co chi phi, sau do tao record nghiep vu tuong ung.
- Migration da tao va apply: `20260607000000_his_workflow_schema`.
