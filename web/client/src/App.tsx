import { useEffect, useMemo, useState } from "react";

// ─── Types ────────────────────────────────────────────────────────────────────
type Page =
  | "dashboard"
  | "products"
  | "sales-orders"
  | "invoices"
  | "purchase-orders"
  | "service-jobs";

type User = { email: string; role: string; fullName: string };

type ApiEnvelope<T> = {
  data: T | null;
  error: { message: string; hint?: string } | null;
  meta: Record<string, unknown>;
};

type LookupCategory = { CategoryId: number; Name: string };
type LookupSupplier = { SupplierId: number; Name: string };
type LookupLocation = {
  LocationId: number;
  Code: string;
  Name: string;
  LocationType: string;
};
type LookupCustomer = {
  CustomerId: number;
  Name: string;
  Email: string | null;
  Phone: string | null;
};
type LookupData = {
  categories: LookupCategory[];
  suppliers: LookupSupplier[];
  locations: LookupLocation[];
  customers?: LookupCustomer[];
};

type Product = {
  ProductId: number;
  Sku: string;
  Name: string;
  UnitOfMeasure: string;
  UnitCost: number;
  ListPrice: number;
  ReorderLevel: number;
  CategoryName: string;
  SupplierName: string | null;
};
type ProductListMeta = {
  page: number;
  pageSize: number;
  total: number;
  totalPages: number;
  sortBy: string;
  sortDir: "asc" | "desc";
};
type ProductDetails = Product & {
  Description?: string | null;
  stockByLocation: Array<{
    LocationId: number;
    Code: string;
    Name: string;
    LocationType: string;
    QuantityOnHand: number;
  }>;
};

type SalesOrder = {
  SalesOrderId: number;
  OrderNumber: string;
  OrderDate: string;
  OrderStatus: string;
  CustomerName: string;
  FulfillmentLocation: string;
  LinesTotal: number;
};

type Invoice = {
  InvoiceId: number;
  InvoiceNumber: string;
  InvoiceDate: string;
  PaymentStatus: string;
  OrderNumber: string;
  OrderStatus: string;
  CustomerName: string;
  CustomerEmail: string;
  FulfillingLocation: string;
  SubTotal: number;
  TaxAmount: number;
  TotalAmount: number;
  SalesRep: string | null;
};

type PurchaseOrder = {
  PurchaseOrderId: number;
  PoNumber: string;
  OrderDate: string;
  Status: string;
  Supplier: string;
  ShipToLocation: string;
  CreatedBy: string | null;
  LineCount: number;
  TotalQtyOrdered: number;
  TotalQtyReceived: number;
  TotalOrderedValue: number;
  TotalReceivedValue: number;
  FulfilmentPct: number;
};

type ServiceJob = {
  JobId: number;
  JobNumber: string;
  JobStatus: string;
  CustomerName: string;
  LocationName: string;
  LocationCode: string;
  ManagerName: string | null;
  AssigneeName: string | null;
  ScheduledDate: string;
  CompletedDate: string | null;
  MaterialCount: number;
  EstimatedCost: number;
  Notes: string | null;
  CreatedAt: string;
};
type ServiceJobMaterial = {
  JobMaterialId: number;
  LineNumber: number;
  ProductId: number;
  Sku: string;
  ProductName: string;
  UnitCost: number;
  UnitOfMeasure: string;
  QuantityRequired: number;
  QuantityUsed: number | null;
  LineTotal: number;
};
type ServiceJobDetail = ServiceJob & {
  CustomerId: number;
  CustomerEmail: string | null;
  CustomerPhone: string | null;
  materials: ServiceJobMaterial[];
};
type DraftMaterial = { tempId: number; productId: string; quantity: string };

// ─── API Helper ───────────────────────────────────────────────────────────────
function makeApi(token: string) {
  return async function apiFetch<T>(
    url: string,
    init?: RequestInit,
  ): Promise<ApiEnvelope<T>> {
    const headers: Record<string, string> = {
      "Content-Type": "application/json",
      ...(init?.headers as Record<string, string>),
    };
    if (token) headers["Authorization"] = `Bearer ${token}`;
    const response = await fetch(url, { ...init, headers });
    const payload = (await response.json().catch(() => ({}))) as Partial<
      ApiEnvelope<T>
    >;
    if (!response.ok)
      throw new Error(
        payload.error?.message || response.statusText || "Request failed",
      );
    return payload as ApiEnvelope<T>;
  };
}

// ─── Utilities ────────────────────────────────────────────────────────────────
function fmt(n: number) {
  return new Intl.NumberFormat("en-PH", {
    style: "currency",
    currency: "PHP",
  }).format(n);
}
function fmtDate(s: string) {
  return new Date(s).toLocaleDateString("en-PH", {
    year: "numeric",
    month: "short",
    day: "numeric",
  });
}
function initials(name: string) {
  return name
    .split(" ")
    .map((w) => w[0])
    .join("")
    .slice(0, 2)
    .toUpperCase();
}

// ─── Status Badge ─────────────────────────────────────────────────────────────
function Badge({ status }: { status: string }) {
  const map: Record<string, string> = {
    PAID: "badge-green",
    RECEIVED: "badge-green",
    COMPLETED: "badge-green",
    UNPAID: "badge-amber",
    PARTIAL: "badge-amber",
    SHIPPED: "badge-amber",
    PENDING: "badge-amber",
    OPEN: "badge-blue",
    CONFIRMED: "badge-blue",
    IN_PROGRESS: "badge-blue",
    DRAFT: "badge-muted",
    CANCELLED: "badge-muted",
  };
  return (
    <span className={`badge ${map[status] ?? "badge-muted"}`}>{status}</span>
  );
}

// ─── Progress Bar ─────────────────────────────────────────────────────────────
function ProgressBar({ pct }: { pct: number }) {
  const color =
    pct >= 100
      ? "var(--green)"
      : pct === 0
        ? "var(--text-dim)"
        : "var(--amber)";
  return (
    <div className="progress-wrap">
      <div className="progress-bar">
        <div
          className="progress-fill"
          style={{ width: `${Math.min(pct, 100)}%`, background: color }}
        />
      </div>
      <span className="progress-label">{pct.toFixed(0)}%</span>
    </div>
  );
}

// ═════════════════════════════════════════════════════════════════════════════
// LOGIN PAGE
// ═════════════════════════════════════════════════════════════════════════════
function LoginPage({
  onLogin,
}: {
  onLogin: (token: string, user: User) => void;
}) {
  const [email, setEmail] = useState("admin@ashcol.local");
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError("");
    try {
      const res = await fetch("/api/auth/login", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email, password }),
      });
      const data = (await res.json()) as ApiEnvelope<{
        token: string;
        email: string;
        role: string;
        fullName: string;
      }>;
      if (!res.ok || !data.data) {
        setError(data.error?.message ?? "Login failed");
        return;
      }
      onLogin(data.data.token, {
        email: data.data.email,
        role: data.data.role,
        fullName: data.data.fullName,
      });
    } catch {
      setError("Cannot connect to API. Make sure npm run dev is running.");
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="login-bg">
      <div className="login-card">
        {/* Ashcol Logo */}
        <div className="login-logo">
          <img
            src="/assets/ash-logo.jpg"
            alt="Ashcol"
            className="login-logo-img"
          />
        </div>

        <h2 className="login-title">Welcome back!</h2>
        <p className="login-sub">Sign in to your account to continue.</p>

        {error && (
          <div className="alert alert-error" style={{ marginBottom: "1rem" }}>
            &#9888; {error}
          </div>
        )}

        <form onSubmit={handleSubmit}>
          <div className="login-field">
            <span className="login-field-label">Email</span>
            <input
              id="login-email"
              type="email"
              value={email}
              required
              autoFocus
              onChange={(e) => setEmail(e.target.value)}
              placeholder="Enter your email"
              className="login-input"
            />
          </div>
          <div className="login-field">
            <span className="login-field-label">Password</span>
            <input
              id="login-password"
              type="password"
              value={password}
              required
              onChange={(e) => setPassword(e.target.value)}
              placeholder="Password"
              className="login-input"
            />
          </div>
          <button
            id="login-submit"
            type="submit"
            className="btn-signin"
            disabled={loading}
          >
            {loading ? "Signing in..." : "Sign in"}
          </button>
        </form>

        <div className="demo-hint">
          <p className="dem-label">Demo Credentials</p>
          <p>
            <strong>admin@ashcol.local</strong> / admin123 - Admin
          </p>
          <p>
            <strong>juan.delacruz@ashcol.local</strong> / staff123 - Staff
          </p>
          <p>
            <strong>maria.santos@ashcol.local</strong> / staff123 - Staff
          </p>
        </div>
      </div>
    </div>
  );
}

// ── Nav SVG icons (from assets/icons/) ────────────────────────────────────
const SvgIcon = ({
  children,
  vb = "0 0 100 100",
}: {
  children: React.ReactNode;
  vb?: string;
}) => (
  <svg
    width="20"
    height="20"
    viewBox={vb}
    fill="none"
    xmlns="http://www.w3.org/2000/svg"
    style={{ flexShrink: 0 }}
  >
    {children}
  </svg>
);

const DashboardIcon = ({ weight = 2.4 }: { weight?: number }) => (
  <SvgIcon>
    <path
      d="M41.6667 87.4997H14.5C13.3954 87.4997 12.5 86.6042 12.5 85.4997V48.7133C12.5 48.2016 12.6962 47.7093 13.0481 47.3378L48.5481 9.86558C49.3369 9.03289 50.663 9.03289 51.4519 9.86557L86.9519 47.3378C87.3038 47.7093 87.5 48.2016 87.5 48.7133V85.4997C87.5 86.6042 86.6046 87.4997 85.5 87.4997H58.3333M41.6667 87.4997V62.9997C41.6667 62.7235 41.8905 62.4997 42.1667 62.4997H57.8333C58.1095 62.4997 58.3333 62.7235 58.3333 62.9997V87.4997M41.6667 87.4997H58.3333"
      stroke="currentColor"
      strokeWidth={weight}
      strokeLinecap="round"
      strokeLinejoin="round"
    />
  </SvgIcon>
);

const ProductsIcon = () => (
  <SvgIcon>
    <path
      d="M62.8594 10.8066C62.9589 10.8066 63.0766 10.8057 63.1826 10.8359C63.2858 10.8654 63.3778 10.9256 63.4434 11.0361L91.2002 27.4844C91.548 27.6092 91.7656 27.9586 91.7656 28.3955L91.7666 88.0654C91.7666 88.3971 91.6555 88.6815 91.4541 88.8828C91.2528 89.084 90.9687 89.1942 90.6377 89.1943H30.9678C30.8015 89.1943 30.6578 89.1673 30.5273 89.1094C30.3974 89.0516 30.2846 88.9652 30.1758 88.8564L30.1748 88.8555L8.56934 66.2217V66.2207C8.46154 66.1125 8.37572 66.0012 8.31836 65.8721C8.26043 65.7416 8.23342 65.5985 8.2334 65.4326V11.9355C8.2334 11.6039 8.34448 11.3195 8.5459 11.1182C8.74729 10.9171 9.0312 10.8066 9.3623 10.8066H62.8594ZM32.0957 86.9365H89.5078V29.5244H68.1035L68.1045 44.8564C68.1044 45.1879 67.9932 45.4716 67.792 45.6729C67.5907 45.8741 67.3067 45.9853 66.9756 45.9854H53.6006C53.2691 45.9853 52.9854 45.8741 52.7842 45.6729C52.583 45.4715 52.4718 45.1875 52.4717 44.8564V29.5244H32.0957V86.9365ZM10.4912 64.9795L29.8389 85.2432V28.959L10.4912 14.1943V64.9795ZM54.7295 43.7275H65.8467V29.5244H54.7295V43.7275ZM68.3438 27.2666H86.4668L62.5234 13.0635H47.0391L68.3438 27.2666ZM32.6338 13.0635L53.9385 27.2666H64.2793L42.9727 13.0635H32.6338ZM31.3096 27.2666H49.875L28.5703 13.0635H12.7451L31.3096 27.2666Z"
      fill="currentColor"
      stroke="currentColor"
      strokeWidth="0.2"
    />
  </SvgIcon>
);

const SalesOrderIcon = () => (
  <SvgIcon>
    <path
      d="M26.8359 11.8115C27.5026 11.6935 28.219 12.092 28.4072 12.8428L30.9033 22.1611L50.3613 17.0557H50.3623C51.156 16.8578 51.9586 17.2542 52.1602 18.0566L56.2979 33.3604L71.4102 29.3193L71.4111 29.3184C72.2054 29.1201 73.0089 29.5178 73.21 30.3213H73.209L80.9209 58.9502L87.9229 57.1279L88.0723 57.0977C88.8156 56.981 89.5332 57.3767 89.7217 58.1299H89.7207L91.5557 64.8877L91.5566 64.8906V64.8916C92.2362 67.4242 90.7773 70.156 88.2363 70.6445L63.3643 77.2002C63.7317 82.0361 60.6311 86.5749 55.793 87.833L55.792 87.832C50.9551 89.1854 45.9266 86.7787 43.877 82.4365L39.6689 83.584H39.667C38.8732 83.7819 38.0706 83.3856 37.8691 82.583L21.1777 21.1221L13.1143 23.1387C11.1577 23.6277 9.00675 22.4546 8.41992 20.4004C7.83242 18.3439 9.10624 16.2902 11.1582 15.7041L11.1592 15.7031L26.7041 11.8418L26.8359 11.8115ZM60.2705 76.6904C59.5276 72.9756 55.6343 70.2485 51.5547 71.1279L51.1592 71.2246C47.1315 72.2795 44.8292 76.4033 46.0762 80.4316C47.2264 84.1704 51.1577 86.2811 54.9941 85.2266L55.333 85.1201C58.7936 83.9484 61.1061 80.4988 60.2705 76.6914V76.6904ZM11.8584 18.4082C11.265 18.5926 11.0796 19.1633 11.207 19.6504C11.2708 19.8939 11.4124 20.1121 11.6162 20.2461C11.8189 20.3793 12.0872 20.4326 12.4121 20.3398L12.4141 20.3389L21.877 18.0215L21.8887 18.0186V18.0205H22.1777C22.7824 18.0205 23.3783 18.5207 23.5771 19.1162L23.5781 19.1191L40.2705 80.4834L42.9775 79.8281C42.5174 76.8871 43.3547 73.6747 45.4883 71.3652L43.0469 71.998C42.2526 72.1963 41.4491 71.7996 41.248 70.9961V70.9951L26.0049 14.8477L11.8584 18.4082ZM87.3203 60.3262C77.6338 62.9157 65.6724 66.073 56.251 68.5723C59.1708 69.4779 61.6103 71.7544 62.667 74.5928L87.4385 68.0391L87.627 67.9775C88.4797 67.6512 88.9547 66.7847 88.7988 65.8799L88.7559 65.6855L87.3203 60.3262ZM36.2402 41.665L43.6484 68.8955L78.2168 59.748L70.8076 32.5186L36.2402 41.665ZM31.7021 24.9609L35.4414 38.8643L53.498 34.0635L49.7588 20.1582L31.7021 24.9609Z"
      fill="currentColor"
      stroke="currentColor"
      strokeWidth="0.1"
    />
  </SvgIcon>
);

const InvoicesIcon = () => (
  <SvgIcon>
    <path
      d="M81.9886 11.8593C80.1146 9.98526 77.6248 8.95428 74.9724 8.95428L27.3587 8.95312C24.7065 8.95312 22.2179 9.9841 20.3425 11.8582C18.4685 13.7322 17.4375 16.222 17.4375 18.8743V82.3652C17.4375 85.0175 18.4685 87.506 20.3425 89.3814C22.2166 91.2555 24.7064 92.2865 27.3587 92.2865H74.9784C77.6306 92.2865 80.1192 91.2555 81.9946 89.3814C83.8686 87.5074 84.8996 85.0176 84.8996 82.3652V18.8743C84.895 16.2233 83.864 13.7336 81.9899 11.8593L81.9886 11.8593ZM80.9287 82.3685C80.9287 85.6517 78.2602 88.32 74.9771 88.32H27.3574C24.0742 88.32 21.4059 85.6516 21.4059 82.3685V18.8746C21.4059 15.5914 24.0743 12.923 27.3574 12.923H74.9771C78.2603 12.923 80.9287 15.5915 80.9287 18.8746V82.3685Z"
      fill="currentColor"
    />
    <path
      d="M41.826 45.2495L35.2923 51.7845L32.7282 49.2204C31.9547 48.4469 30.6953 48.4469 29.9229 49.2204C29.1494 49.9939 29.1494 51.2533 29.9229 52.0257L33.8925 55.9953C34.2671 56.3698 34.7692 56.5774 35.2969 56.5774C35.8245 56.5774 36.3279 56.3698 36.7013 55.9953L44.6393 48.0573C45.4128 47.2837 45.4128 46.0243 44.6393 45.252C43.8658 44.4773 42.5982 44.4727 41.8259 45.2497L41.826 45.2495Z"
      fill="currentColor"
    />
    <path
      d="M41.826 65.0877L35.2923 71.6214L32.7282 69.0574C31.9547 68.2838 30.6953 68.2838 29.9229 69.0574C29.1494 69.8309 29.1494 71.0903 29.9229 71.8627L33.8925 75.8322C34.2671 76.2068 34.7692 76.4144 35.2969 76.4144C35.8245 76.4144 36.3279 76.2068 36.7013 75.8322L44.6393 67.8942C45.4128 67.1207 45.4128 65.8613 44.6393 65.089C43.8658 64.3143 42.5982 64.3143 41.8259 65.0878L41.826 65.0877Z"
      fill="currentColor"
    />
    <path
      d="M41.826 25.4062L35.2923 31.9399L32.7282 29.3758C31.9547 28.6023 30.6953 28.6023 29.9229 29.3758C29.1494 30.1494 29.1494 31.4088 29.9229 32.1811L33.8925 36.1507C34.2671 36.5253 34.7692 36.7329 35.2969 36.7329C35.8245 36.7329 36.3279 36.5253 36.7013 36.1507L44.6393 28.2127C45.4128 27.4392 45.4128 26.1798 44.6393 25.4074C43.8658 24.6339 42.5982 24.6339 41.8259 25.4063L41.826 25.4062Z"
      fill="currentColor"
    />
    <path
      d="M71.01 48.6367H51.1676C50.0706 48.6367 49.1846 49.5262 49.1846 50.6198C49.1846 51.7134 50.0741 52.6029 51.1676 52.6029H71.01C72.107 52.6029 72.993 51.7134 72.993 50.6198C72.993 49.5227 72.1035 48.6367 71.01 48.6367Z"
      fill="currentColor"
    />
    <path
      d="M71.01 72.4473H51.1676C50.0706 72.4473 49.1846 73.3368 49.1846 74.4303C49.1846 75.5239 50.0741 76.4134 51.1676 76.4134H71.01C72.107 76.4134 72.993 75.5239 72.993 74.4303C72.993 73.3368 72.1035 72.4473 71.01 72.4473Z"
      fill="currentColor"
    />
    <path
      d="M71.01 28.7939H51.1676C50.0706 28.7939 49.1846 29.6834 49.1846 30.777C49.1846 31.8706 50.0741 32.7601 51.1676 32.7601H71.01C72.107 32.7601 72.993 31.8706 72.993 30.777C72.993 29.6834 72.1035 28.7939 71.01 28.7939Z"
      fill="currentColor"
    />
  </SvgIcon>
);

const PurchaseOrderIcon = () => (
  <SvgIcon>
    <path
      d="M68.5186 87.0366V53.3494C68.5186 52.0862 69.5922 51.0626 70.8333 51.0626C72.1115 51.0626 73.148 52.0607 73.148 53.3494V87.0366H77.8123C82.8706 87.0366 87.0372 82.8822 87.0372 77.8117V22.1871C87.0372 17.1288 82.8828 12.9621 77.8123 12.9621H22.1877C17.1294 12.9621 12.9627 17.1166 12.9627 22.1871V77.8117C12.9627 82.87 17.1172 87.0366 22.1877 87.0366H26.8519V64.9594C26.8519 63.6562 27.9255 62.5994 29.1666 62.5994C30.4449 62.5994 31.4814 63.626 31.4814 64.9594V87.0366H40.7407V41.8241C40.7407 40.5552 41.8143 39.5268 43.0554 39.5268C44.3342 39.5268 45.3707 40.5173 45.3707 41.8241V87.0366H54.6294V24.5252C54.6294 23.2533 55.7036 22.222 56.9447 22.222C58.223 22.222 59.2594 23.2544 59.2594 24.5252V87.0366H68.5186ZM8.33301 22.1874C8.33301 14.5359 14.5964 8.33301 22.1874 8.33301H77.812C85.4634 8.33301 91.6663 14.5964 91.6663 22.1874V77.812C91.6663 85.4634 85.403 91.6663 77.812 91.6663H22.1874C14.5359 91.6663 8.33301 85.403 8.33301 77.812V22.1874Z"
      fill="currentColor"
    />
  </SvgIcon>
);

const ServiceJobsIcon = () => (
  <SvgIcon>
    <path
      d="M49.9994 8.33398C27.0252 8.33398 8.33301 27.0262 8.33301 50.0003C8.33301 60.2724 12.0765 69.6802 18.2613 76.9514C18.3405 77.0735 18.4313 77.189 18.5374 77.2951C18.5614 77.319 18.5883 77.3343 18.6123 77.3568C26.2569 86.1161 37.4886 91.6659 49.9997 91.6659C62.5107 91.6659 73.7421 86.1161 81.3871 77.3568C81.4111 77.335 81.4394 77.3183 81.4619 77.2951C81.568 77.189 81.6596 77.072 81.738 76.9514C87.9229 69.6795 91.6663 60.2714 91.6663 50.0003C91.6663 27.0262 72.9742 8.33398 50 8.33398H49.9994ZM49.9994 87.5C39.3503 87.5 29.7317 83.0315 22.8995 75.8794L25.7536 73.0253C28.5111 70.2686 32.176 68.75 36.0729 68.75H63.9261C67.8229 68.75 71.4878 70.2686 74.2447 73.0245L77.0988 75.8787C70.2672 83.0306 60.6484 87.5 49.999 87.5H49.9994ZM79.8168 72.7049L77.1909 70.079C73.6472 66.5354 68.9367 64.583 63.9261 64.583H36.0729C31.0622 64.583 26.3524 66.5354 22.8087 70.079L20.1828 72.7049C15.3676 66.3981 12.4996 58.5289 12.4996 50.0005C12.4996 29.3236 29.3213 12.5008 49.9994 12.5008C70.6763 12.5008 87.4991 29.3225 87.4991 50.0005C87.4991 58.5295 84.6312 66.3984 79.8166 72.7049H79.8168ZM49.9994 27.084C40.8101 27.084 33.3324 34.5607 33.3324 43.7509C33.3324 52.9402 40.8091 60.4178 49.9994 60.4178C59.1886 60.4178 66.6663 52.9412 66.6663 43.7509C66.6663 34.5607 59.1888 27.084 49.9994 27.084ZM49.9994 56.2505C43.1067 56.2505 37.4996 50.6432 37.4996 43.7507C37.4996 36.8581 43.1069 31.251 49.9994 31.251C56.8918 31.251 62.4991 36.8583 62.4991 43.7507C62.4991 50.6434 56.8918 56.2505 49.9994 56.2505Z"
      fill="currentColor"
    />
  </SvgIcon>
);

const LogoutIcon = () => (
  <SvgIcon vb="0 0 24 24">
    <path
      d="M15 17L20 12L15 7"
      stroke="currentColor"
      strokeWidth="2.2"
      strokeLinecap="round"
      strokeLinejoin="round"
    />
    <path
      d="M20 12H9"
      stroke="currentColor"
      strokeWidth="2.2"
      strokeLinecap="round"
      strokeLinejoin="round"
    />
    <path
      d="M11 19H6C4.9 19 4 18.1 4 17V7C4 5.9 4.9 5 6 5H11"
      stroke="currentColor"
      strokeWidth="2.2"
      strokeLinecap="round"
      strokeLinejoin="round"
    />
  </SvgIcon>
);

const SearchIcon = () => (
  <svg
    width="16"
    height="16"
    viewBox="0 0 24 24"
    fill="none"
    xmlns="http://www.w3.org/2000/svg"
    style={{ flexShrink: 0 }}
  >
    <circle cx="11" cy="11" r="7" stroke="currentColor" strokeWidth="2.2" />
    <path
      d="M20 20L16.65 16.65"
      stroke="currentColor"
      strokeWidth="2.2"
      strokeLinecap="round"
      strokeLinejoin="round"
    />
  </svg>
);

const MenuIcon = () => (
  <svg
    width="20"
    height="20"
    viewBox="0 0 24 24"
    fill="none"
    xmlns="http://www.w3.org/2000/svg"
  >
    <path
      d="M4 7H20"
      stroke="currentColor"
      strokeWidth="2.2"
      strokeLinecap="round"
    />
    <path
      d="M4 12H20"
      stroke="currentColor"
      strokeWidth="2.2"
      strokeLinecap="round"
    />
    <path
      d="M4 17H20"
      stroke="currentColor"
      strokeWidth="2.2"
      strokeLinecap="round"
    />
  </svg>
);

const CloseIcon = () => (
  <svg
    width="20"
    height="20"
    viewBox="0 0 24 24"
    fill="none"
    xmlns="http://www.w3.org/2000/svg"
  >
    <path
      d="M6 6L18 18"
      stroke="currentColor"
      strokeWidth="2.2"
      strokeLinecap="round"
    />
    <path
      d="M18 6L6 18"
      stroke="currentColor"
      strokeWidth="2.2"
      strokeLinecap="round"
    />
  </svg>
);

function Sidebar({
  page,
  setPage,
  onLogout,
  isOpen,
  onNavigate,
}: {
  page: Page;
  setPage: (p: Page) => void;
  onLogout: () => void;
  isOpen: boolean;
  onNavigate: () => void;
}) {
  const navItems: { id: Page; icon: React.ReactNode; label: string }[] = [
    { id: "dashboard", icon: <DashboardIcon />, label: "Dashboard" },
    { id: "products", icon: <ProductsIcon />, label: "Products" },
    { id: "sales-orders", icon: <SalesOrderIcon />, label: "Sales Orders" },
    { id: "invoices", icon: <InvoicesIcon />, label: "Invoices" },
    {
      id: "purchase-orders",
      icon: <PurchaseOrderIcon />,
      label: "Purchase Orders",
    },
    { id: "service-jobs", icon: <ServiceJobsIcon />, label: "Service Jobs" },
  ];

  return (
    <aside className={`sidebar${isOpen ? " open" : ""}`}>
      {/* Brand */}
      <div className="sidebar-brand">
        <img src="/assets/ash-logo.jpg" alt="Ashcol" className="sb-logo" />
        <div className="b-text">
          <strong>Ashcol Inventory</strong>
          <span>Management System</span>
        </div>
      </div>
      <div className="sidebar-divider" />

      {/* Nav */}
      <nav className="sidebar-nav">
        {navItems.map((item) => (
          <button
            key={item.id}
            id={`nav-${item.id}`}
            className={`nav-item${page === item.id ? " active" : ""}`}
            onClick={() => {
              setPage(item.id);
              onNavigate();
            }}
          >
            <span className="nav-icon-wrap">{item.icon}</span>
            {item.label}
          </button>
        ))}
      </nav>

      {/* Logout */}
      <div className="sidebar-footer">
        <button
          id="btn-logout"
          className="btn-logout"
          onClick={() => {
            onLogout();
            onNavigate();
          }}
        >
          <span className="nav-icon">
            <LogoutIcon />
          </span>
          Log Out
        </button>
      </div>
    </aside>
  );
}

// TOP BAR
function TopBar({
  user,
  menuOpen,
  onToggleMenu,
  theme,
  onToggleTheme,
}: {
  user: User;
  menuOpen: boolean;
  onToggleMenu: () => void;
  theme: "light" | "dark";
  onToggleTheme: () => void;
}) {
  return (
    <div className="top-bar">
      <button
        type="button"
        className="mobile-menu-btn"
        onClick={onToggleMenu}
        aria-label={menuOpen ? "Close navigation" : "Open navigation"}
        aria-expanded={menuOpen}
      >
        {menuOpen ? <CloseIcon /> : <MenuIcon />}
      </button>
      <div className="top-bar-search">
        <span className="search-icon">
          <SearchIcon />
        </span>
        <input
          type="text"
          placeholder="Search product, supplier, order"
          className="search-input"
        />
      </div>
      <div className="top-bar-user">
        <button
          type="button"
          className="btn-theme-toggle"
          onClick={onToggleTheme}
          aria-label={theme === "dark" ? "Switch to light mode" : "Switch to dark mode"}
        >
          {theme === "dark" ? (
            <svg
              width="20"
              height="20"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="2"
              strokeLinecap="round"
              strokeLinejoin="round"
            >
              <circle cx="12" cy="12" r="4" />
              <path d="M12 2v2M12 20v2M4.93 4.93l1.41 1.41M17.66 17.66l1.41 1.41M2 12h2M20 12h2M6.34 17.66l-1.41 1.41M19.07 4.93l-1.41 1.41" />
            </svg>
          ) : (
            <svg
              width="20"
              height="20"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="2.5"
              strokeLinecap="round"
              strokeLinejoin="round"
            >
              <path d="M12 3a6 6 0 0 0 9 9 9 9 0 1 1-9-9Z" />
            </svg>
          )}
        </button>
        <span className="user-role-badge">{user.role.toUpperCase()}</span>
        <div className="user-avatar-top">{initials(user.fullName)}</div>
      </div>
    </div>
  );
}

// ═════════════════════════════════════════════════════════════════════════════
// DASHBOARD PAGE
// ═════════════════════════════════════════════════════════════════════════════
function DashboardPage() {
  const cards = [
    {
      id: "stat-products",
      title: "Total Products",
      subtitle: "Active inventory items",
      icon: "https://storage.googleapis.com/tagjs-prod.appspot.com/v1/yKnbVvJgNU/yar91cle_expires_30_days.png",
      variant: "blue",
    },
    {
      id: "stat-low-stock",
      title: "Low Stock Items",
      subtitle: "Requires restocking",
      icon: "https://storage.googleapis.com/tagjs-prod.appspot.com/v1/yKnbVvJgNU/ze8x556n_expires_30_days.png",
      variant: "red",
    },
    {
      id: "stat-orders",
      title: "Pending Orders",
      subtitle: "Quantity in hand",
      icon: "https://storage.googleapis.com/tagjs-prod.appspot.com/v1/yKnbVvJgNU/0zk1egwh_expires_30_days.png",
      variant: "amber",
    },
    {
      id: "stat-revenue",
      title: "Revenue Collected",
      subtitle: "Quantity in hand",
      icon: "https://storage.googleapis.com/tagjs-prod.appspot.com/v1/yKnbVvJgNU/xo97mehz_expires_30_days.png",
      variant: "green",
    },
  ];

  return (
    <div className="main dashboard-page">
      <div className="dashboard-copy">
        <h1>Dashboard</h1>
        <p>Real-time overview of your inventory system.</p>
      </div>

      <div className="dashboard-cards">
        {cards.map((card) => (
          <div
            key={card.id}
            id={card.id}
            className={`dashboard-card dashboard-card--${card.variant}`}
          >
            <div className="dashboard-card-head">
              <span className="dashboard-card-title">{card.title}</span>
              <span className="dashboard-card-icon">
                <img
                  src={card.icon}
                  alt=""
                  aria-hidden="true"
                  className="dashboard-card-icon-img"
                />
              </span>
            </div>
            <div className="dashboard-card-divider" />
            <div className="dashboard-card-subtitle">{card.subtitle}</div>
          </div>
        ))}
      </div>
    </div>
  );
}

// ═════════════════════════════════════════════════════════════════════════════
// PRODUCTS PAGE
// ═════════════════════════════════════════════════════════════════════════════
function ProductsPage({ api }: { api: ReturnType<typeof makeApi> }) {
  const [lookups, setLookups] = useState<LookupData>({
    categories: [],
    suppliers: [],
    locations: [],
  });
  const [products, setProducts] = useState<Product[]>([]);
  const [meta, setMeta] = useState<ProductListMeta>({
    page: 1,
    pageSize: 10,
    total: 0,
    totalPages: 1,
    sortBy: "Sku",
    sortDir: "asc",
  });
  const [loading, setLoading] = useState(false);
  const [search, setSearch] = useState("");
  const [filters, setFilters] = useState({
    q: "",
    categoryId: "",
    supplierId: "",
    sortBy: "sku",
    sortDir: "asc",
    page: 1,
  });
  const [selected, setSelected] = useState<ProductDetails | null>(null);
  const [detailLoading, setDL] = useState(false);
  const [message, setMessage] = useState<{ text: string; ok: boolean } | null>(
    null,
  );
  const [draft, setDraft] = useState({
    sku: "",
    name: "",
    categoryId: "",
    supplierId: "",
    unitOfMeasure: "PCS",
    unitCost: "0",
    listPrice: "0",
    reorderLevel: "0",
    description: "",
  });
  const [adj, setAdj] = useState({
    productId: "",
    locationId: "",
    quantityDelta: "",
    note: "",
  });
  const [saving, setSaving] = useState(false);

  const startIdx = useMemo(
    () => (meta.total === 0 ? 0 : (meta.page - 1) * meta.pageSize + 1),
    [meta],
  );
  const endIdx = useMemo(
    () => Math.min(meta.total, meta.page * meta.pageSize),
    [meta],
  );

  useEffect(() => {
    api<LookupData>("/api/lookups").then((r) =>
      setLookups(r.data ?? { categories: [], suppliers: [], locations: [] }),
    );
    loadProducts(filters);
  }, []);

  async function loadProducts(f = filters) {
    setLoading(true);
    const params = new URLSearchParams({
      page: String(f.page),
      pageSize: "10",
      sortBy: f.sortBy,
      sortDir: f.sortDir,
    });
    if (f.q) params.set("q", f.q);
    if (f.categoryId) params.set("categoryId", f.categoryId);
    if (f.supplierId) params.set("supplierId", f.supplierId);
    try {
      const res = await api<Product[]>(`/api/products?${params}`);
      setProducts(res.data ?? []);
      const m = res.meta as Partial<ProductListMeta>;
      setMeta({
        page: Number(m.page || 1),
        pageSize: Number(m.pageSize || 10),
        total: Number(m.total || 0),
        totalPages: Number(m.totalPages || 1),
        sortBy: String(m.sortBy || "Sku"),
        sortDir: String(m.sortDir || "asc") as "asc" | "desc",
      });
    } finally {
      setLoading(false);
    }
  }

  async function loadDetails(id: number) {
    setDL(true);
    try {
      const r = await api<ProductDetails>(`/api/products/${id}`);
      setSelected(r.data);
    } finally {
      setDL(false);
    }
  }

  function applyFilters() {
    const next = { ...filters, q: search.trim(), page: 1 };
    setFilters(next);
    loadProducts(next);
  }

  function resetFilters() {
    const next = {
      q: "",
      categoryId: "",
      supplierId: "",
      sortBy: "sku",
      sortDir: "asc",
      page: 1,
    };
    setSearch("");
    setFilters(next);
    loadProducts(next);
  }

  function setSort(sortBy: string) {
    const next = {
      ...filters,
      sortBy,
      sortDir:
        filters.sortBy === sortBy && filters.sortDir === "asc" ? "desc" : "asc",
      page: 1,
    };
    setFilters(next);
    loadProducts(next);
  }

  function goPage(p: number) {
    const next = {
      ...filters,
      page: Math.max(1, Math.min(meta.totalPages, p)),
    };
    setFilters(next);
    loadProducts(next);
  }

  async function submitProduct(e: React.FormEvent) {
    e.preventDefault();
    setSaving(true);
    setMessage(null);
    try {
      await api<{ productId: number }>("/api/products", {
        method: "POST",
        body: JSON.stringify({
          ...draft,
          categoryId: Number(draft.categoryId),
          supplierId: draft.supplierId ? Number(draft.supplierId) : null,
          unitCost: Number(draft.unitCost),
          listPrice: Number(draft.listPrice),
          reorderLevel: Number(draft.reorderLevel),
        }),
      });
      setDraft({
        sku: "",
        name: "",
        categoryId: "",
        supplierId: "",
        unitOfMeasure: "PCS",
        unitCost: "0",
        listPrice: "0",
        reorderLevel: "0",
        description: "",
      });
      setMessage({ text: "Product created successfully.", ok: true });
      loadProducts();
    } catch (err) {
      setMessage({
        text: String(err instanceof Error ? err.message : err),
        ok: false,
      });
    } finally {
      setSaving(false);
    }
  }

  async function submitAdj(e: React.FormEvent) {
    e.preventDefault();
    setSaving(true);
    setMessage(null);
    try {
      await api<{ movementId: number }>("/api/stock-adjustments", {
        method: "POST",
        body: JSON.stringify({
          productId: Number(adj.productId),
          locationId: Number(adj.locationId),
          quantityDelta: Number(adj.quantityDelta),
          note: adj.note,
        }),
      });
      setAdj({ productId: "", locationId: "", quantityDelta: "", note: "" });
      setMessage({ text: "Stock adjustment saved.", ok: true });
      loadProducts();
      if (selected) loadDetails(selected.ProductId);
    } catch (err) {
      setMessage({
        text: String(err instanceof Error ? err.message : err),
        ok: false,
      });
    } finally {
      setSaving(false);
    }
  }

  return (
    <div className="main">
      <div className="page-header">
        <h1>Products</h1>
        <p>Browse and manage your product catalog</p>
      </div>

      <div className="card" style={{ marginBottom: "1.25rem" }}>
        <div className="section-head">
          <h2>Catalog</h2>
          <button
            className="btn btn-ghost btn-sm"
            id="btn-refresh-products"
            onClick={() => loadProducts()}
            disabled={loading}
          >
            ↻ Refresh
          </button>
        </div>

        <div className="toolbar">
          <div className="field">
            <label>Search</label>
            <input
              id="search-products"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="SKU or Name"
              onKeyDown={(e) => e.key === "Enter" && applyFilters()}
            />
          </div>
          <div className="field">
            <label>Category</label>
            <select
              id="filter-category"
              value={filters.categoryId}
              onChange={(e) => {
                const next = {
                  ...filters,
                  categoryId: e.target.value,
                  page: 1,
                  q: search.trim(),
                };
                setFilters(next);
                loadProducts(next);
              }}
            >
              <option value="">All</option>
              {lookups.categories.map((c) => (
                <option key={c.CategoryId} value={c.CategoryId}>
                  {c.Name}
                </option>
              ))}
            </select>
          </div>
          <div className="field">
            <label>Supplier</label>
            <select
              id="filter-supplier"
              value={filters.supplierId}
              onChange={(e) => {
                const next = {
                  ...filters,
                  supplierId: e.target.value,
                  page: 1,
                  q: search.trim(),
                };
                setFilters(next);
                loadProducts(next);
              }}
            >
              <option value="">All</option>
              {lookups.suppliers.map((s) => (
                <option key={s.SupplierId} value={s.SupplierId}>
                  {s.Name}
                </option>
              ))}
            </select>
          </div>
          <button
            className="btn btn-sm"
            id="btn-apply-filters"
            onClick={applyFilters}
            disabled={loading}
          >
            Apply
          </button>
          <button
            className="btn btn-ghost btn-sm"
            id="btn-reset-filters"
            onClick={resetFilters}
            disabled={loading}
          >
            Reset
          </button>
        </div>

        <div className="table-wrap">
          <table>
            <thead>
              <tr>
                <th>
                  <button className="head-btn" onClick={() => setSort("sku")}>
                    SKU
                  </button>
                </th>
                <th>
                  <button className="head-btn" onClick={() => setSort("name")}>
                    Name
                  </button>
                </th>
                <th>
                  <button
                    className="head-btn"
                    onClick={() => setSort("category")}
                  >
                    Category
                  </button>
                </th>
                <th>UOM</th>
                <th>
                  <button className="head-btn" onClick={() => setSort("price")}>
                    List Price
                  </button>
                </th>
                <th>Supplier</th>
                <th>Action</th>
              </tr>
            </thead>
            <tbody>
              {loading && (
                <tr>
                  <td colSpan={7} className="text-muted">
                    Loading…
                  </td>
                </tr>
              )}
              {!loading && products.length === 0 && (
                <tr>
                  <td colSpan={7} className="text-muted">
                    No products match your filters.
                  </td>
                </tr>
              )}
              {!loading &&
                products.map((p) => (
                  <tr key={p.ProductId}>
                    <td className="mono">{p.Sku}</td>
                    <td>{p.Name}</td>
                    <td>{p.CategoryName}</td>
                    <td>{p.UnitOfMeasure}</td>
                    <td>{fmt(Number(p.ListPrice))}</td>
                    <td>{p.SupplierName ?? "—"}</td>
                    <td>
                      <button
                        className="btn btn-sm"
                        onClick={() => loadDetails(p.ProductId)}
                      >
                        Details
                      </button>
                    </td>
                  </tr>
                ))}
            </tbody>
          </table>
        </div>

        <div className="pagination">
          <span className="text-muted">
            Showing {startIdx}–{endIdx} of {meta.total}
          </span>
          <div className="pager-buttons">
            <button
              className="btn btn-ghost btn-sm"
              onClick={() => goPage(meta.page - 1)}
              disabled={meta.page <= 1 || loading}
            >
              ‹ Prev
            </button>
            <span>
              Page {meta.page} / {meta.totalPages}
            </span>
            <button
              className="btn btn-ghost btn-sm"
              onClick={() => goPage(meta.page + 1)}
              disabled={meta.page >= meta.totalPages || loading}
            >
              Next ›
            </button>
          </div>
        </div>
      </div>

      <div className="grid-2">
        {/* Actions panel */}
        <div className="card">
          <h2 style={{ margin: "0 0 1rem" }}>Inventory Actions</h2>
          {message && (
            <div
              className={`alert ${message.ok ? "alert-success" : "alert-error"}`}
            >
              {message.text}
            </div>
          )}

          <p
            className="text-muted"
            style={{ fontSize: "0.82rem", margin: "0 0 0.5rem" }}
          >
            Add Product
          </p>
          <form
            className="form-grid"
            onSubmit={submitProduct}
            style={{ marginBottom: "1.5rem" }}
          >
            <label>
              SKU
              <input
                required
                value={draft.sku}
                onChange={(e) =>
                  setDraft((s) => ({ ...s, sku: e.target.value }))
                }
              />
            </label>
            <label>
              Name
              <input
                required
                value={draft.name}
                onChange={(e) =>
                  setDraft((s) => ({ ...s, name: e.target.value }))
                }
              />
            </label>
            <label>
              Category
              <select
                required
                value={draft.categoryId}
                onChange={(e) =>
                  setDraft((s) => ({ ...s, categoryId: e.target.value }))
                }
              >
                <option value="">Select…</option>
                {lookups.categories.map((c) => (
                  <option key={c.CategoryId} value={c.CategoryId}>
                    {c.Name}
                  </option>
                ))}
              </select>
            </label>
            <label>
              Supplier
              <select
                value={draft.supplierId}
                onChange={(e) =>
                  setDraft((s) => ({ ...s, supplierId: e.target.value }))
                }
              >
                <option value="">None</option>
                {lookups.suppliers.map((s) => (
                  <option key={s.SupplierId} value={s.SupplierId}>
                    {s.Name}
                  </option>
                ))}
              </select>
            </label>
            <div className="responsive-grid-2">
              <label>
                UOM
                <input
                  value={draft.unitOfMeasure}
                  onChange={(e) =>
                    setDraft((s) => ({ ...s, unitOfMeasure: e.target.value }))
                  }
                />
              </label>
              <label>
                Reorder Level
                <input
                  type="number"
                  min="0"
                  value={draft.reorderLevel}
                  onChange={(e) =>
                    setDraft((s) => ({ ...s, reorderLevel: e.target.value }))
                  }
                />
              </label>
              <label>
                Unit Cost
                <input
                  type="number"
                  step="0.01"
                  min="0"
                  value={draft.unitCost}
                  onChange={(e) =>
                    setDraft((s) => ({ ...s, unitCost: e.target.value }))
                  }
                />
              </label>
              <label>
                List Price
                <input
                  type="number"
                  step="0.01"
                  min="0"
                  value={draft.listPrice}
                  onChange={(e) =>
                    setDraft((s) => ({ ...s, listPrice: e.target.value }))
                  }
                />
              </label>
            </div>
            <button className="btn" disabled={saving}>
              {saving ? "Saving…" : "Create Product"}
            </button>
          </form>

          <p
            className="text-muted"
            style={{ fontSize: "0.82rem", margin: "0 0 0.5rem" }}
          >
            Stock Adjustment
          </p>
          <form className="form-grid" onSubmit={submitAdj}>
            <label>
              Product
              <select
                required
                value={adj.productId}
                onChange={(e) =>
                  setAdj((s) => ({ ...s, productId: e.target.value }))
                }
              >
                <option value="">Select product…</option>
                {products.map((p) => (
                  <option key={p.ProductId} value={p.ProductId}>
                    {p.Sku} — {p.Name}
                  </option>
                ))}
              </select>
            </label>
            <label>
              Location
              <select
                required
                value={adj.locationId}
                onChange={(e) =>
                  setAdj((s) => ({ ...s, locationId: e.target.value }))
                }
              >
                <option value="">Select location…</option>
                {lookups.locations.map((l) => (
                  <option key={l.LocationId} value={l.LocationId}>
                    {l.Code} — {l.Name}
                  </option>
                ))}
              </select>
            </label>
            <label>
              Quantity Delta
              <input
                required
                type="number"
                value={adj.quantityDelta}
                onChange={(e) =>
                  setAdj((s) => ({ ...s, quantityDelta: e.target.value }))
                }
                placeholder="Positive or negative"
              />
            </label>
            <label>
              Note
              <textarea
                rows={2}
                value={adj.note}
                onChange={(e) =>
                  setAdj((s) => ({ ...s, note: e.target.value }))
                }
              />
            </label>
            <button className="btn" disabled={saving}>
              {saving ? "Saving…" : "Post Adjustment"}
            </button>
          </form>
        </div>

        {/* Detail panel */}
        <div className="card">
          <h2 style={{ margin: "0 0 1rem" }}>Product Details</h2>
          {!selected && !detailLoading && (
            <p className="text-muted">
              Select a product from the table to view stock by location.
            </p>
          )}
          {detailLoading && <p className="text-muted">Loading…</p>}
          {selected && !detailLoading && (
            <>
              <div className="detail-panel" style={{ marginBottom: "1rem" }}>
                <h3>{selected.Name}</h3>
                <p>
                  {selected.Sku} · {selected.CategoryName} ·{" "}
                  {selected.SupplierName ?? "No supplier"}
                </p>
                <div className="responsive-grid-2 detail-grid">
                  <div>
                    <span className="text-muted">Unit Cost</span>
                    <br />
                    <strong>{fmt(Number(selected.UnitCost))}</strong>
                  </div>
                  <div>
                    <span className="text-muted">List Price</span>
                    <br />
                    <strong>{fmt(Number(selected.ListPrice))}</strong>
                  </div>
                  <div>
                    <span className="text-muted">UOM</span>
                    <br />
                    <strong>{selected.UnitOfMeasure}</strong>
                  </div>
                  <div>
                    <span className="text-muted">Reorder Level</span>
                    <br />
                    <strong>{selected.ReorderLevel}</strong>
                  </div>
                </div>
              </div>
              <p
                className="text-muted"
                style={{
                  fontSize: "0.78rem",
                  textTransform: "uppercase",
                  fontWeight: 600,
                  letterSpacing: "0.05em",
                  margin: "0 0 0.5rem",
                }}
              >
                Stock by Location
              </p>
              <div className="table-wrap">
                <table>
                  <thead>
                    <tr>
                      <th>Location</th>
                      <th>Type</th>
                      <th>On Hand</th>
                    </tr>
                  </thead>
                  <tbody>
                    {selected.stockByLocation.map((row) => (
                      <tr key={row.LocationId}>
                        <td>
                          {row.Code} — {row.Name}
                        </td>
                        <td>{row.LocationType}</td>
                        <td
                          style={{
                            fontWeight: 700,
                            color:
                              row.QuantityOnHand === 0
                                ? "var(--red)"
                                : row.QuantityOnHand < 5
                                  ? "var(--amber)"
                                  : "var(--green)",
                          }}
                        >
                          {row.QuantityOnHand}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </>
          )}
        </div>
      </div>
    </div>
  );
}

// ═════════════════════════════════════════════════════════════════════════════
// SERVICE JOBS PAGE
// ═════════════════════════════════════════════════════════════════════════════
function ServiceJobsPage({ api }: { api: ReturnType<typeof makeApi> }) {
  const [jobs, setJobs] = useState<ServiceJob[]>([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState<string | null>(null);
  const [selected, setSelected] = useState<ServiceJobDetail | null>(null);
  const [detailLoading, setDL] = useState(false);
  const [customers, setCustomers] = useState<LookupCustomer[]>([]);
  const [locations, setLocations] = useState<LookupLocation[]>([]);
  const [allProducts, setAllProducts] = useState<Product[]>([]);
  const [showForm, setShowForm] = useState(false);
  const [message, setMessage] = useState<{ text: string; ok: boolean } | null>(
    null,
  );
  const [saving, setSaving] = useState(false);
  const [completing, setCompleting] = useState(false);
  const [draft, setDraft] = useState({
    customerId: "",
    locationId: "",
    assigneeName: "",
    scheduledDate: "",
    notes: "",
  });
  const [draftMats, setDraftMats] = useState<DraftMaterial[]>([
    { tempId: 1, productId: "", quantity: "1" },
  ]);

  useEffect(() => {
    if (!showForm) return;
    const previousOverflow = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    return () => {
      document.body.style.overflow = previousOverflow;
    };
  }, [showForm]);

  useEffect(() => {
    loadAll();
  }, []);

  async function loadAll() {
    setLoading(true);
    try {
      const [jobsRes, lookupsRes, prodsRes] = await Promise.all([
        api<ServiceJob[]>("/api/service-jobs"),
        api<LookupData>("/api/lookups"),
        api<Product[]>("/api/products?pageSize=50&sortBy=name"),
      ]);
      setJobs(jobsRes.data ?? []);
      const lk = lookupsRes.data;
      setCustomers((lk as any)?.customers ?? []);
      setLocations(lk?.locations ?? []);
      setAllProducts(prodsRes.data ?? []);
    } finally {
      setLoading(false);
    }
  }

  async function loadDetail(id: number) {
    setDL(true);
    setSelected(null);
    try {
      const r = await api<ServiceJobDetail>(`/api/service-jobs/${id}`);
      setSelected(r.data);
    } finally {
      setDL(false);
    }
  }

  async function submitJob(e: React.FormEvent) {
    e.preventDefault();
    const mats = draftMats.filter((m) => m.productId && Number(m.quantity) > 0);
    if (mats.length === 0) {
      setMessage({ text: "Add at least one material line.", ok: false });
      return;
    }
    setSaving(true);
    setMessage(null);
    try {
      const r = await api<{ jobId: number; jobNumber: string }>(
        "/api/service-jobs",
        {
          method: "POST",
          body: JSON.stringify({
            customerId: Number(draft.customerId),
            locationId: Number(draft.locationId),
            assigneeName: draft.assigneeName,
            scheduledDate: draft.scheduledDate,
            notes: draft.notes,
            materials: mats.map((m, i) => ({
              productId: Number(m.productId),
              quantity: Number(m.quantity),
              lineNumber: i + 1,
            })),
          }),
        },
      );
      setMessage({
        text: `Job ${r.data?.jobNumber} created! Awaiting assignment.`,
        ok: true,
      });
      setShowForm(false);
      setDraft({
        customerId: "",
        locationId: "",
        assigneeName: "",
        scheduledDate: "",
        notes: "",
      });
      setDraftMats([{ tempId: Date.now(), productId: "", quantity: "1" }]);
      loadAll();
    } catch (err) {
      setMessage({
        text: String(err instanceof Error ? err.message : err),
        ok: false,
      });
    } finally {
      setSaving(false);
    }
  }

  async function startJob(jobId: number) {
    try {
      await api(`/api/service-jobs/${jobId}/start`, { method: "PATCH" });
      setMessage({ text: "Job started and marked In Progress.", ok: true });
      loadAll();
      if (selected?.JobId === jobId) loadDetail(jobId);
    } catch (err) {
      setMessage({
        text: String(err instanceof Error ? err.message : err),
        ok: false,
      });
    }
  }

  async function completeJob(jobId: number) {
    if (
      !window.confirm(
        "Mark this job COMPLETE? All bill-of-materials items will be deducted from inventory.",
      )
    )
      return;
    setCompleting(true);
    setMessage(null);
    try {
      const r = await api<{ completed: boolean; materialsDeducted: number }>(
        `/api/service-jobs/${jobId}/complete`,
        { method: "PATCH" },
      );
      setMessage({
        text: `✅ Job completed! ${r.data?.materialsDeducted ?? 0} material line(s) deducted from inventory.`,
        ok: true,
      });
      loadAll();
      loadDetail(jobId);
    } catch (err) {
      setMessage({
        text: String(err instanceof Error ? err.message : err),
        ok: false,
      });
    } finally {
      setCompleting(false);
    }
  }

  const displayed = useMemo(
    () => (filter ? jobs.filter((j) => j.JobStatus === filter) : jobs),
    [jobs, filter],
  );
  const byStatus = useMemo(
    () =>
      jobs.reduce(
        (acc, j) => {
          acc[j.JobStatus] = (acc[j.JobStatus] ?? 0) + 1;
          return acc;
        },
        {} as Record<string, number>,
      ),
    [jobs],
  );
  const statusColor: Record<string, string> = {
    PENDING: "var(--amber)",
    IN_PROGRESS: "var(--blue)",
    COMPLETED: "var(--green)",
    CANCELLED: "var(--text-muted)",
  };
  const summaryCards = [
    {
      key: null,
      label: "Total Jobs",
      value: jobs.length,
      foot: "All Jobs",
      color: "var(--blue)",
    },
    {
      key: "COMPLETED",
      label: "Completed Jobs",
      value: byStatus.COMPLETED ?? 0,
      foot: "Finished Jobs",
      color: "var(--green)",
    },
    {
      key: "IN_PROGRESS",
      label: "In Progress Jobs",
      value: byStatus.IN_PROGRESS ?? 0,
      foot: "Ongoing Jobs",
      color: "var(--amber)",
    },
    {
      key: "PENDING",
      label: "Pending Jobs",
      value: byStatus.PENDING ?? 0,
      foot: "Awaiting Jobs",
      color: "var(--amber)",
    },
    {
      key: "CANCELLED",
      label: "Cancelled Jobs",
      value: byStatus.CANCELLED ?? 0,
      foot: "Dropped Jobs",
      color: "var(--red)",
    },
  ] as const;

  return (
    <div className="main service-jobs-page">
      <div className="service-jobs-page-header">
        <h1>Service Jobs</h1>
        <p>
          Installation &amp; service work orders - materials auto-deducted from
          inventory on job completion
        </p>
      </div>

      <div
        className="card service-jobs-summary-card"
        style={{ marginBottom: "1.25rem" }}
      >
        <div className="section-head service-jobs-summary-head">
          <h2>Overall Service Jobs</h2>
        </div>
        <div className="service-jobs-summary-grid">
          {summaryCards.map((card) => (
            <button
              key={card.label}
              type="button"
              className="service-jobs-summary-tile"
              style={
                {
                  "--summary-color": card.color,
                  opacity:
                    filter === card.key
                      ? 1
                      : filter && filter !== card.key
                        ? 0.7
                        : 1,
                } as React.CSSProperties
              }
              onClick={() => setFilter(card.key)}
            >
              <div className="service-jobs-summary-label">{card.label}</div>
              <div className="service-jobs-summary-value">{card.value}</div>
              <div className="service-jobs-summary-foot">{card.foot}</div>
            </button>
          ))}
        </div>
      </div>

      {message && (
        <div
          className={`alert ${message.ok ? "alert-success" : "alert-error"}`}
          style={{ marginBottom: "1rem" }}
        >
          {message.text}
        </div>
      )}

      <div
        className="service-jobs-layout"
        style={{
          display: "grid",
          gridTemplateColumns: "1fr 220px",
          gap: "1.25rem",
          alignItems: "start",
        }}
      >
        {/* Left: job list */}
        <div className="card">
          <div className="section-head">
            <h2>Products</h2>
            <button
              className="btn btn-sm"
              onClick={() => {
                setShowForm((v) => !v);
                setMessage(null);
              }}
            >
              {showForm ? "✕ Close" : "Add New Service Job"}
            </button>
          </div>

          {showForm && (
            <div
              className="service-job-form-backdrop"
              onClick={() => setShowForm(false)}
              role="presentation"
            >
              <form
                className="service-job-form-modal"
                onSubmit={submitJob}
                onClick={(e) => e.stopPropagation()}
              >
                <div className="service-job-form-header">
                  <h3>New Service Job</h3>
                  <button
                    type="button"
                    className="service-job-form-close"
                    onClick={() => setShowForm(false)}
                    aria-label="Close form"
                  >
                    ×
                  </button>
                </div>

                <div className="service-job-form-body">
                  <label className="service-job-field service-job-field--text">
                    <span>Customer</span>
                    <select
                      required
                      value={draft.customerId}
                      onChange={(e) =>
                        setDraft((s) => ({ ...s, customerId: e.target.value }))
                      }
                    >
                      <option value="">Select Customer</option>
                      {customers.map((c) => (
                        <option key={c.CustomerId} value={c.CustomerId}>
                          {c.Name}
                        </option>
                      ))}
                    </select>
                  </label>

                  <label className="service-job-field service-job-field--text">
                    <span>Location</span>
                    <select
                      required
                      value={draft.locationId}
                      onChange={(e) =>
                        setDraft((s) => ({ ...s, locationId: e.target.value }))
                      }
                    >
                      <option value="">Select Location</option>
                      {locations.map((l) => (
                        <option key={l.LocationId} value={l.LocationId}>
                          {l.Code} — {l.Name}
                        </option>
                      ))}
                    </select>
                  </label>

                  <label className="service-job-field service-job-field--text">
                    <span>Assigned Technician</span>
                    <input
                      value={draft.assigneeName}
                      onChange={(e) =>
                        setDraft((s) => ({
                          ...s,
                          assigneeName: e.target.value,
                        }))
                      }
                      placeholder="e.g. Juan Dela Cruz"
                    />
                  </label>

                  <label className="service-job-field service-job-field--text">
                    <span>Scheduled Date</span>
                    <input
                      type="datetime-local"
                      required
                      value={draft.scheduledDate}
                      onChange={(e) =>
                        setDraft((s) => ({
                          ...s,
                          scheduledDate: e.target.value,
                        }))
                      }
                    />
                  </label>

                  <label className="service-job-field service-job-field--textarea">
                    <span>Notes</span>
                    <textarea
                      rows={3}
                      value={draft.notes}
                      onChange={(e) =>
                        setDraft((s) => ({ ...s, notes: e.target.value }))
                      }
                      placeholder="Job description or special instructions"
                    />
                  </label>

                  <div className="service-job-materials-head">
                    <p>BILL OF MATERIALS</p>
                    <button
                      type="button"
                      className="service-job-add-row"
                      onClick={() =>
                        setDraftMats((m) => [
                          ...m,
                          { tempId: Date.now(), productId: "", quantity: "1" },
                        ])
                      }
                    >
                      + Add Row
                    </button>
                  </div>

                  <div className="service-job-materials-list">
                    {draftMats.map((mat) => (
                      <div
                        key={mat.tempId}
                        className="service-job-material-row"
                      >
                        <select
                          required
                          value={mat.productId}
                          onChange={(e) =>
                            setDraftMats((m) =>
                              m.map((x) =>
                                x.tempId === mat.tempId
                                  ? { ...x, productId: e.target.value }
                                  : x,
                              ),
                            )
                          }
                        >
                          <option value="">Select product</option>
                          {allProducts.map((p) => (
                            <option key={p.ProductId} value={p.ProductId}>
                              {p.Sku} — {p.Name}
                            </option>
                          ))}
                        </select>
                        <input
                          type="number"
                          min="1"
                          required
                          value={mat.quantity}
                          placeholder="0"
                          onChange={(e) =>
                            setDraftMats((m) =>
                              m.map((x) =>
                                x.tempId === mat.tempId
                                  ? { ...x, quantity: e.target.value }
                                  : x,
                              ),
                            )
                          }
                        />
                        <button
                          type="button"
                          className="service-job-row-remove"
                          onClick={() =>
                            setDraftMats((m) =>
                              m.filter((x) => x.tempId !== mat.tempId),
                            )
                          }
                          disabled={draftMats.length === 1}
                          aria-label="Remove material row"
                        >
                          ×
                        </button>
                      </div>
                    ))}
                  </div>
                </div>

                <div className="service-job-form-footer">
                  <button
                    type="button"
                    className="service-job-discard"
                    onClick={() => setShowForm(false)}
                  >
                    Discard
                  </button>
                  <button className="service-job-create" disabled={saving}>
                    {saving ? "Creating…" : "Create Job"}
                  </button>
                </div>
              </form>
            </div>
          )}

          <div className="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>JOB #</th>
                  <th>Customer</th>
                  <th>LOCATION</th>
                  <th>TECHNICIAN</th>
                  <th>SCHEDULE</th>
                  <th>ITEMS</th>
                  <th>Status</th>
                  <th></th>
                </tr>
              </thead>
              <tbody>
                {loading && (
                  <tr>
                    <td colSpan={8} className="text-muted">
                      Loading…
                    </td>
                  </tr>
                )}
                {!loading && displayed.length === 0 && (
                  <tr>
                    <td colSpan={8}>
                      <div
                        style={{
                          textAlign: "center",
                          padding: "2.5rem 1rem",
                          color: "var(--text-muted)",
                        }}
                      >
                        <div
                          style={{ fontSize: "2.5rem", marginBottom: "0.5rem" }}
                        >
                          🔧
                        </div>
                        <p style={{ margin: "0 0 0.75rem" }}>
                          No service jobs yet.
                        </p>
                        <button
                          className="btn btn-sm"
                          onClick={() => setShowForm(true)}
                        >
                          ➕ Create First Job
                        </button>
                      </div>
                    </td>
                  </tr>
                )}
                {!loading &&
                  displayed.map((j) => (
                    <tr
                      key={j.JobId}
                      style={{ cursor: "pointer" }}
                      onClick={() => loadDetail(j.JobId)}
                    >
                      <td className="mono">{j.JobNumber}</td>
                      <td>{j.CustomerName}</td>
                      <td className="mono">{j.LocationCode}</td>
                      <td>
                        {j.AssigneeName ?? (
                          <span className="text-muted">—</span>
                        )}
                      </td>
                      <td>{fmtDate(j.ScheduledDate)}</td>
                      <td style={{ textAlign: "center" }}>{j.MaterialCount}</td>
                      <td>
                        <Badge status={j.JobStatus} />
                      </td>
                      <td>
                        <button
                          className="btn btn-sm"
                          onClick={(e) => {
                            e.stopPropagation();
                            loadDetail(j.JobId);
                          }}
                        >
                          View
                        </button>
                      </td>
                    </tr>
                  ))}
              </tbody>
            </table>
          </div>
        </div>

        {/* Right: detail panel */}
        <div className="card service-jobs-details-card">
          <h2 style={{ margin: "0 0 1rem" }}>Job Details</h2>
          {!selected && !detailLoading && (
            <p className="text-muted" style={{ fontSize: "0.85rem" }}>
              Click on any job row to view its details, materials list, and
              available actions.
            </p>
          )}
          {detailLoading && <p className="text-muted">Loading…</p>}
          {selected && !detailLoading && (
            <>
              <div className="detail-panel" style={{ marginBottom: "1rem" }}>
                <div
                  style={{
                    display: "flex",
                    justifyContent: "space-between",
                    alignItems: "flex-start",
                    marginBottom: "0.4rem",
                  }}
                >
                  <h3 style={{ margin: 0 }}>{selected.JobNumber}</h3>
                  <Badge status={selected.JobStatus} />
                </div>
                <p style={{ margin: "0 0 0.75rem", fontSize: "0.85rem" }}>
                  {selected.CustomerName}
                </p>
                <div className="responsive-grid-2 detail-grid">
                  <div>
                    <span className="text-muted">Location</span>
                    <br />
                    <strong>
                      {selected.LocationCode} — {selected.LocationName}
                    </strong>
                  </div>
                  <div>
                    <span className="text-muted">Technician</span>
                    <br />
                    <strong>{selected.AssigneeName ?? "—"}</strong>
                  </div>
                  <div>
                    <span className="text-muted">Scheduled</span>
                    <br />
                    <strong>{fmtDate(selected.ScheduledDate)}</strong>
                  </div>
                  <div>
                    <span className="text-muted">Completed</span>
                    <br />
                    <strong>
                      {selected.CompletedDate
                        ? fmtDate(selected.CompletedDate)
                        : "—"}
                    </strong>
                  </div>
                  <div>
                    <span className="text-muted">Est. Cost</span>
                    <br />
                    <strong style={{ color: "var(--amber)" }}>
                      {fmt(
                        selected.materials.reduce(
                          (s, m) => s + Number(m.LineTotal),
                          0,
                        ),
                      )}
                    </strong>
                  </div>
                  <div>
                    <span className="text-muted">Manager</span>
                    <br />
                    <strong>{selected.ManagerName ?? "—"}</strong>
                  </div>
                </div>
                {selected.Notes && (
                  <p
                    style={{
                      marginTop: "0.75rem",
                      marginBottom: 0,
                      fontSize: "0.82rem",
                      color: "var(--text-muted)",
                      borderTop: "1px solid var(--border)",
                      paddingTop: "0.5rem",
                    }}
                  >
                    📝 {selected.Notes}
                  </p>
                )}
              </div>

              <p
                className="text-muted"
                style={{
                  fontSize: "0.75rem",
                  textTransform: "uppercase",
                  fontWeight: 600,
                  letterSpacing: "0.05em",
                  margin: "0 0 0.5rem",
                }}
              >
                Bill of Materials{" "}
                {selected.JobStatus === "COMPLETED"
                  ? "✓ Deducted"
                  : "— Pending"}
              </p>
              <div className="table-wrap" style={{ marginBottom: "1rem" }}>
                <table>
                  <thead>
                    <tr>
                      <th>SKU</th>
                      <th>Product</th>
                      <th>Qty</th>
                      <th>Cost</th>
                    </tr>
                  </thead>
                  <tbody>
                    {selected.materials.map((m) => (
                      <tr key={m.JobMaterialId}>
                        <td className="mono">{m.Sku}</td>
                        <td style={{ fontSize: "0.8rem" }}>{m.ProductName}</td>
                        <td
                          style={{
                            textAlign: "center",
                            fontWeight: 700,
                            color:
                              m.QuantityUsed !== null
                                ? "var(--green)"
                                : "var(--text)",
                          }}
                        >
                          {m.QuantityRequired}
                          {m.QuantityUsed !== null && " ✓"}
                        </td>
                        <td>{fmt(Number(m.LineTotal))}</td>
                      </tr>
                    ))}
                    <tr
                      style={{
                        fontWeight: 700,
                        borderTop: "2px solid var(--border2)",
                      }}
                    >
                      <td
                        colSpan={3}
                        style={{
                          textAlign: "right",
                          color: "var(--text-muted)",
                          fontSize: "0.78rem",
                        }}
                      >
                        TOTAL EST. COST
                      </td>
                      <td style={{ color: "var(--amber)" }}>
                        {fmt(
                          selected.materials.reduce(
                            (s, m) => s + Number(m.LineTotal),
                            0,
                          ),
                        )}
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>

              {selected.JobStatus === "PENDING" && (
                <button
                  className="btn btn-ghost"
                  style={{ width: "100%", marginBottom: "0.5rem" }}
                  onClick={() => startJob(selected.JobId)}
                >
                  ▶ Start Job
                </button>
              )}
              {(selected.JobStatus === "PENDING" ||
                selected.JobStatus === "IN_PROGRESS") && (
                <button
                  className="btn btn-green"
                  style={{ width: "100%" }}
                  disabled={completing}
                  onClick={() => completeJob(selected.JobId)}
                >
                  {completing
                    ? "⏳ Processing…"
                    : "✅ Mark Complete & Deduct Stock"}
                </button>
              )}
              {selected.JobStatus === "COMPLETED" && (
                <div
                  className="alert alert-success"
                  style={{ marginBottom: 0, justifyContent: "center" }}
                >
                  ✅ All materials deducted from inventory
                </div>
              )}
              {selected.JobStatus === "CANCELLED" && (
                <div
                  className="alert alert-warning"
                  style={{ marginBottom: 0 }}
                >
                  ⚠ This job was cancelled. No stock was deducted.
                </div>
              )}
            </>
          )}
        </div>
      </div>
    </div>
  );
}

// ═════════════════════════════════════════════════════════════════════════════
// SALES ORDERS PAGE
// ═════════════════════════════════════════════════════════════════════════════
function SalesOrdersPage({ api }: { api: ReturnType<typeof makeApi> }) {
  const [orders, setOrders] = useState<SalesOrder[]>([]);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(1);
  const pageSize = 5;

  const orderDateValue = (order: SalesOrder) =>
    new Date(order.OrderDate).getTime();
  const sevenDaysAgo = Date.now() - 7 * 24 * 60 * 60 * 1000;

  const statusMeta = (status: string) => {
    const key = status
      .trim()
      .toUpperCase()
      .replace(/[-\s]+/g, "_");
    const meta: Record<string, { label: string; color: string }> = {
      DRAFT: { label: "Draft", color: "var(--text-muted)" },
      CONFIRMED: { label: "Confirmed", color: "var(--blue)" },
      SHIPPED: { label: "Shipped", color: "var(--amber)" },
      COMPLETED: { label: "Completed", color: "var(--green)" },
      CANCELLED: { label: "Cancelled", color: "var(--red)" },
      RETURNED: { label: "Returned", color: "var(--red)" },
      OUT_FOR_DELIVERY: { label: "Out for delivery", color: "var(--blue)" },
      DELAYED: { label: "Delayed", color: "var(--amber)" },
      PENDING: { label: "Pending", color: "var(--amber)" },
    };

    return meta[key] ?? { label: status, color: "var(--text-muted)" };
  };

  const loadOrders = async () => {
    setLoading(true);
    try {
      const r = await api<SalesOrder[]>("/api/sales-orders");
      setOrders(r.data ?? []);
      setPage(1);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    void loadOrders();
  }, []);

  const displayedOrders = useMemo(() => orders, [orders]);
  const summary = useMemo(() => {
    const recentOrders = orders.filter(
      (order) => orderDateValue(order) >= sevenDaysAgo,
    );
    const revenue = orders
      .filter((order) =>
        ["CONFIRMED", "SHIPPED", "COMPLETED"].includes(
          order.OrderStatus.toUpperCase(),
        ),
      )
      .reduce((total, order) => total + Number(order.LinesTotal), 0);

    const countByStatus = (status: string) =>
      orders.filter((order) => order.OrderStatus.toUpperCase() === status)
        .length;

    return {
      totalOrders: orders.length,
      revenue,
      completedOrders: countByStatus("COMPLETED"),
      pendingOrders: countByStatus("PENDING"),
      cancelledOrders: countByStatus("CANCELLED"),
      recentOrders: recentOrders.length,
    };
  }, [orders]);

  const totalPages = Math.max(1, Math.ceil(displayedOrders.length / pageSize));
  const pageOrders = useMemo(() => {
    const start = (page - 1) * pageSize;
    return displayedOrders.slice(start, start + pageSize);
  }, [displayedOrders, page]);

  useEffect(() => {
    setPage((current) => Math.min(Math.max(1, current), totalPages));
  }, [totalPages]);

  return (
    <div className="main sales-orders-page">
      <div className="sales-orders-page-header">
        <h1>Sales Order</h1>
        <p>All customer orders from the database</p>
      </div>

      <div className="sales-orders-summary card">
        <div className="section-head sales-orders-summary-head">
          <h2>Overall Sales Order</h2>
        </div>

        <div className="sales-orders-summary-grid">
          <div className="sales-orders-summary-tile sales-orders-summary-tile--wide">
            <div className="sales-orders-summary-label sales-orders-summary-label--green">
              Total Orders
            </div>
            <div className="sales-orders-summary-main-row">
              <div className="sales-orders-summary-value">
                {summary.totalOrders}
              </div>
              <div className="sales-orders-summary-revenue">
                {fmt(summary.revenue)}
              </div>
            </div>
            <div className="sales-orders-summary-foot">
              Last 7 days <span>Revenue</span>
            </div>
          </div>

          <div className="sales-orders-summary-tile">
            <div className="sales-orders-summary-label sales-orders-summary-label--green">
              Completed Orders
            </div>
            <div className="sales-orders-summary-value">
              {summary.completedOrders}
            </div>
            <div className="sales-orders-summary-foot">Last 7 days</div>
          </div>

          <div className="sales-orders-summary-tile">
            <div className="sales-orders-summary-label sales-orders-summary-label--amber">
              Pending Orders
            </div>
            <div className="sales-orders-summary-value">
              {summary.pendingOrders}
            </div>
            <div className="sales-orders-summary-foot">Last 7 days</div>
          </div>

          <div className="sales-orders-summary-tile">
            <div className="sales-orders-summary-label sales-orders-summary-label--red">
              Cancelled Orders
            </div>
            <div className="sales-orders-summary-value">
              {summary.cancelledOrders}
            </div>
            <div className="sales-orders-summary-foot">Last 7 days</div>
          </div>
        </div>
      </div>

      <div className="sales-orders-frame">
        <div className="sales-orders-toolbar">
          <div className="sales-orders-heading">
            <h2>All Orders</h2>
          </div>

          <button
            type="button"
            className="sales-orders-refresh"
            onClick={loadOrders}
            disabled={loading}
          >
            <span
              aria-hidden="true"
              className={
                loading
                  ? "sales-orders-refresh-icon spin"
                  : "sales-orders-refresh-icon"
              }
            >
              ↺
            </span>
            Refresh
          </button>
        </div>

        <div className="sales-orders-table-shell">
          <table className="sales-orders-table">
            <thead>
              <tr>
                <th>ORDER#</th>
                <th>DATE</th>
                <th>CUSTOMER</th>
                <th>LOCATION</th>
                <th>STATUS</th>
                <th>TOTAL</th>
              </tr>
            </thead>
            <tbody>
              {loading && (
                <tr>
                  <td colSpan={6} className="sales-orders-empty">
                    Loading…
                  </td>
                </tr>
              )}

              {!loading && displayedOrders.length === 0 && (
                <tr>
                  <td colSpan={6} className="sales-orders-empty">
                    No sales orders yet.
                  </td>
                </tr>
              )}

              {!loading &&
                pageOrders.map((order) => {
                  const status = statusMeta(order.OrderStatus);

                  return (
                    <tr key={order.SalesOrderId}>
                      <td>
                        <div className="sales-orders-order-number">
                          {order.OrderNumber}
                        </div>
                      </td>
                      <td className="sales-orders-date">
                        {fmtDate(order.OrderDate)}
                      </td>
                      <td className="sales-orders-customer">
                        {order.CustomerName || "—"}
                      </td>
                      <td className="sales-orders-location">
                        {order.FulfillmentLocation || "—"}
                      </td>
                      <td>
                        <span
                          className="sales-orders-status"
                          style={{ color: status.color }}
                        >
                          {status.label}
                        </span>
                      </td>
                      <td className="sales-orders-total">
                        {fmt(Number(order.LinesTotal))}
                      </td>
                    </tr>
                  );
                })}
            </tbody>
          </table>
        </div>

        <div className="sales-orders-footer">
          <button
            type="button"
            className="sales-orders-pagination-btn"
            onClick={() => setPage((current) => Math.max(1, current - 1))}
            disabled={page <= 1 || loading || displayedOrders.length === 0}
          >
            Previous
          </button>

          <p className="sales-orders-details">
            <span>Page </span>
            <strong>{displayedOrders.length === 0 ? 0 : page}</strong>
            <span> of {displayedOrders.length === 0 ? 0 : totalPages}</span>
          </p>

          <button
            type="button"
            className="sales-orders-pagination-btn"
            onClick={() =>
              setPage((current) => Math.min(totalPages, current + 1))
            }
            disabled={
              page >= totalPages || loading || displayedOrders.length === 0
            }
          >
            Next
          </button>
        </div>
      </div>
    </div>
  );
}

// ═════════════════════════════════════════════════════════════════════════════
// INVOICES PAGE
// ═════════════════════════════════════════════════════════════════════════════
function InvoicesPage({ api }: { api: ReturnType<typeof makeApi> }) {
  const [invoices, setInvoices] = useState<Invoice[]>([]);
  const [loading, setLoading] = useState(true);
  const [paying, setPaying] = useState<number | null>(null);
  const [message, setMessage] = useState<{ text: string; ok: boolean } | null>(
    null,
  );
  const [filter, setFilter] = useState<string | null>(null);

  useEffect(() => {
    api<Invoice[]>("/api/invoices")
      .then((r) => setInvoices(r.data ?? []))
      .finally(() => setLoading(false));
  }, []);

  async function markPaid(inv: Invoice) {
    setPaying(inv.InvoiceId);
    try {
      await api(`/api/invoices/${inv.InvoiceId}/pay`, { method: "PATCH" });
      setInvoices((prev) =>
        prev.map((i) =>
          i.InvoiceId === inv.InvoiceId ? { ...i, PaymentStatus: "PAID" } : i,
        ),
      );
      setMessage({ text: `${inv.InvoiceNumber} marked as PAID.`, ok: true });
    } catch (err) {
      setMessage({
        text: String(err instanceof Error ? err.message : err),
        ok: false,
      });
    } finally {
      setPaying(null);
    }
  }

  const totals = useMemo(
    () => ({
      paid: invoices
        .filter((i) => i.PaymentStatus === "PAID")
        .reduce((s, i) => s + Number(i.TotalAmount), 0),
      unpaid: invoices
        .filter((i) => i.PaymentStatus === "UNPAID")
        .reduce((s, i) => s + Number(i.TotalAmount), 0),
    }),
    [invoices],
  );

  const statusMeta = (status: string) => {
    const key = status.trim().toUpperCase();
    const meta: Record<string, { label: string; color: string }> = {
      PAID: { label: "Paid", color: "var(--green)" },
      UNPAID: { label: "Unpaid", color: "var(--amber)" },
      PARTIAL: { label: "Partial", color: "var(--blue)" },
      OVERDUE: { label: "Overdue", color: "var(--red)" },
      DRAFT: { label: "Draft", color: "var(--text-muted)" },
      RETURNED: { label: "Returned", color: "var(--text-muted)" },
      DELAYED: { label: "Delayed", color: "var(--amber)" },
      CONFIRMED: { label: "Confirmed", color: "var(--blue)" },
      SHIPPED: { label: "Shipped", color: "var(--green)" },
    };

    return meta[key] ?? { label: status, color: "var(--text-muted)" };
  };

  const summaryCards = [
    {
      key: null,
      label: "Total Invoice",
      value: invoices.length,
      foot: "Last 7 days",
      color: "var(--green)",
    },
    {
      key: "PAID",
      label: "Collected Revenue",
      value: fmt(totals.paid),
      foot: "Last 7 days",
      color: "var(--green)",
    },
    {
      key: "UNPAID",
      label: "Pending Payments",
      value: invoices.filter((i) => i.PaymentStatus === "UNPAID").length,
      foot: "Last 7 days",
      color: "var(--amber)",
    },
    {
      key: "OVERDUE",
      label: "Overdue Invoices",
      value: invoices.filter((i) => i.PaymentStatus === "UNPAID").length,
      foot: "Last 7 days",
      color: "var(--red)",
    },
  ] as const;

  return (
    <div className="main sales-orders-page invoices-page">
      <div className="sales-orders-page-header invoices-page-header">
        <h1>Invoices</h1>
        <p>Billing records for all completed and shipped orders</p>
      </div>

      <div
        className="card sales-orders-summary invoices-summary"
        style={{ marginBottom: "1.25rem" }}
      >
        <div className="section-head sales-orders-summary-head">
          <h2>Overall Invoices</h2>
        </div>
        <div className="sales-orders-summary-grid invoices-summary-grid">
          {summaryCards.map((card) => (
            <button
              key={card.label}
              type="button"
              className="sales-orders-summary-tile invoices-summary-tile"
              style={
                {
                  "--summary-color": card.color,
                  opacity:
                    filter === card.key
                      ? 1
                      : filter && filter !== card.key
                        ? 0.7
                        : 1,
                } as React.CSSProperties
              }
              onClick={() => setFilter(card.key)}
            >
              <div className="sales-orders-summary-label">{card.label}</div>
              <div className="sales-orders-summary-value">{card.value}</div>
              <div className="sales-orders-summary-foot">{card.foot}</div>
            </button>
          ))}
        </div>
      </div>

      {message && (
        <div
          className={`alert ${message.ok ? "alert-success" : "alert-error"}`}
          style={{ marginBottom: "1rem" }}
        >
          {message.text}
        </div>
      )}

      <div className="sales-orders-frame invoices-frame">
        <div className="sales-orders-toolbar invoices-toolbar">
          <div className="sales-orders-heading">
            <h2>All Invoices</h2>
          </div>

          <button
            type="button"
            className="sales-orders-refresh"
            onClick={() => {
              setLoading(true);
              api<Invoice[]>("/api/invoices")
                .then((r) => setInvoices(r.data ?? []))
                .finally(() => setLoading(false));
            }}
            disabled={loading}
          >
            <span
              aria-hidden="true"
              className={
                loading
                  ? "sales-orders-refresh-icon spin"
                  : "sales-orders-refresh-icon"
              }
            >
              ↺
            </span>
            Refresh
          </button>
        </div>

        <div className="sales-orders-table-shell">
          <table className="sales-orders-table invoices-table">
            <thead>
              <tr>
                <th>INVOICE#</th>
                <th>DATE</th>
                <th>CUSTOMER</th>
                <th>ORDER</th>
                <th>SUB-TOTAL</th>
                <th>VAT(12%)</th>
                <th>TOTAL</th>
                <th>STATUS</th>
                <th>ACTION</th>
              </tr>
            </thead>
            <tbody>
              {loading && (
                <tr>
                  <td colSpan={9} className="sales-orders-empty">
                    Loading…
                  </td>
                </tr>
              )}
              {!loading &&
                invoices
                  .filter((i) => (filter ? i.PaymentStatus === filter : true))
                  .map((inv) => {
                    const status = statusMeta(inv.PaymentStatus);

                    return (
                      <tr key={inv.InvoiceId}>
                        <td>
                          <div className="sales-orders-order-number">
                            {inv.InvoiceNumber}
                          </div>
                        </td>
                        <td className="sales-orders-date">
                          {fmtDate(inv.InvoiceDate)}
                        </td>
                        <td className="sales-orders-customer">
                          {inv.CustomerName}
                        </td>
                        <td className="sales-orders-location">
                          {inv.OrderNumber}
                        </td>
                        <td className="sales-orders-date">
                          {fmt(Number(inv.SubTotal))}
                        </td>
                        <td className="sales-orders-date">
                          {fmt(Number(inv.TaxAmount))}
                        </td>
                        <td className="sales-orders-total">
                          {fmt(Number(inv.TotalAmount))}
                        </td>
                        <td>
                          <span
                            className="sales-orders-status"
                            style={{ color: status.color }}
                          >
                            {status.label}
                          </span>
                        </td>
                        <td>
                          {inv.PaymentStatus === "UNPAID" ? (
                            <button
                              id={`btn-pay-${inv.InvoiceId}`}
                              className="btn btn-green btn-sm"
                              disabled={paying === inv.InvoiceId}
                              onClick={() => markPaid(inv)}
                            >
                              {paying === inv.InvoiceId ? "…" : "✓ Mark Paid"}
                            </button>
                          ) : (
                            <span
                              className="text-muted"
                              style={{ fontSize: "0.78rem" }}
                            >
                              —
                            </span>
                          )}
                        </td>
                      </tr>
                    );
                  })}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}

// ═════════════════════════════════════════════════════════════════════════════
// PURCHASE ORDERS PAGE
// ═════════════════════════════════════════════════════════════════════════════
function PurchaseOrdersPage({ api }: { api: ReturnType<typeof makeApi> }) {
  const [pos, setPos] = useState<PurchaseOrder[]>([]);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(1);
  const [filter, setFilter] = useState<string | null>(null);
  const pageSize = 5;

  const statusMeta = (status: string) => {
    const key = status
      .trim()
      .toUpperCase()
      .replace(/[-\s]+/g, "_");
    const meta: Record<string, { label: string; color: string }> = {
      RECEIVED: { label: "Received", color: "var(--green)" },
      PARTIAL: { label: "Partially Fulfilled", color: "var(--amber)" },
      OPEN: { label: "Awaiting", color: "var(--red)" },
      DELAYED: { label: "Delayed", color: "var(--amber)" },
      CANCELLED: { label: "Cancelled", color: "var(--red)" },
    };

    return meta[key] ?? { label: status, color: "var(--text-muted)" };
  };

  const loadPos = async () => {
    setLoading(true);
    try {
      const r = await api<PurchaseOrder[]>("/api/purchase-orders");
      setPos(r.data ?? []);
      setPage(1);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    void loadPos();
  }, []);

  const filteredPos = useMemo(
    () => pos.filter((po) => (filter ? po.Status === filter : true)),
    [filter, pos],
  );

  const summary = useMemo(
    () => ({
      total: pos.length,
      received: pos.filter((po) => po.Status === "RECEIVED").length,
      partial: pos.filter((po) => po.Status === "PARTIAL").length,
      open: pos.filter((po) => po.Status === "OPEN").length,
    }),
    [pos],
  );

  const totalPages = Math.max(1, Math.ceil(filteredPos.length / pageSize));
  const pagePos = useMemo(() => {
    const start = (page - 1) * pageSize;
    return filteredPos.slice(start, start + pageSize);
  }, [filteredPos, page]);

  useEffect(() => {
    setPage((current) => Math.min(Math.max(1, current), totalPages));
  }, [totalPages]);

  return (
    <div className="main sales-orders-page">
      <div className="sales-orders-page-header">
        <h1>Purchase Orders</h1>
        <p>Replenishment orders sent to suppliers</p>
      </div>

      <div
        className="sales-orders-summary purchase-orders-summary card"
        style={{ marginBottom: "1.25rem" }}
      >
        <div className="section-head sales-orders-summary-head">
          <h2>Overall Purchase Orders</h2>
        </div>

        <div className="sales-orders-summary-grid purchase-orders-summary-grid">
          <button
            type="button"
            className="sales-orders-summary-tile purchase-orders-summary-tile purchase-orders-summary-tile--wide"
            style={
              {
                "--summary-color": "var(--green)",
                opacity: filter === null ? 1 : 0.72,
              } as React.CSSProperties
            }
            onClick={() => setFilter(null)}
          >
            <div className="sales-orders-summary-label sales-orders-summary-label--green">
              Total POs
            </div>
            <div className="sales-orders-summary-main-row">
              <div className="sales-orders-summary-value">{summary.total}</div>
              <div className="sales-orders-summary-revenue">Overall</div>
            </div>
            <div className="sales-orders-summary-foot">
              Total replenishment orders
            </div>
          </button>

          <button
            type="button"
            className="sales-orders-summary-tile purchase-orders-summary-tile"
            style={
              {
                "--summary-color": "var(--green)",
                opacity: filter === "RECEIVED" ? 1 : filter ? 0.72 : 1,
              } as React.CSSProperties
            }
            onClick={() => setFilter("RECEIVED")}
          >
            <div className="sales-orders-summary-label sales-orders-summary-label--green">
              Received POs
            </div>
            <div className="sales-orders-summary-value">{summary.received}</div>
            <div className="sales-orders-summary-foot">Completed</div>
          </button>

          <button
            type="button"
            className="sales-orders-summary-tile purchase-orders-summary-tile"
            style={
              {
                "--summary-color": "var(--amber)",
                opacity: filter === "PARTIAL" ? 1 : filter ? 0.72 : 1,
              } as React.CSSProperties
            }
            onClick={() => setFilter("PARTIAL")}
          >
            <div className="sales-orders-summary-label sales-orders-summary-label--amber">
              Partial POs
            </div>
            <div className="sales-orders-summary-value">{summary.partial}</div>
            <div className="sales-orders-summary-foot">Partially Fulfilled</div>
          </button>

          <button
            type="button"
            className="sales-orders-summary-tile purchase-orders-summary-tile"
            style={
              {
                "--summary-color": "var(--red)",
                opacity: filter === "OPEN" ? 1 : filter ? 0.72 : 1,
              } as React.CSSProperties
            }
            onClick={() => setFilter("OPEN")}
          >
            <div className="sales-orders-summary-label sales-orders-summary-label--red">
              Open POs
            </div>
            <div className="sales-orders-summary-value">{summary.open}</div>
            <div className="sales-orders-summary-foot">Awaiting</div>
          </button>
        </div>
      </div>

      <div className="sales-orders-frame">
        <div className="sales-orders-toolbar">
          <div className="sales-orders-heading">
            <h2>All Purchase Orders</h2>
          </div>

          <button
            type="button"
            className="sales-orders-refresh"
            onClick={loadPos}
            disabled={loading}
          >
            <span
              aria-hidden="true"
              className={
                loading
                  ? "sales-orders-refresh-icon spin"
                  : "sales-orders-refresh-icon"
              }
            >
              ↺
            </span>
            Refresh
          </button>
        </div>

        <div className="sales-orders-table-shell">
          <table className="sales-orders-table">
            <thead>
              <tr>
                <th>PO#</th>
                <th>DATE</th>
                <th>SUPPLIER</th>
                <th>SHIP TO</th>
                <th>LINES</th>
                <th>ORDERED VALUE</th>
                <th>STATUS</th>
                <th>FULFILLMENT</th>
              </tr>
            </thead>
            <tbody>
              {loading && (
                <tr>
                  <td colSpan={8} className="sales-orders-empty">
                    Loading…
                  </td>
                </tr>
              )}
              {!loading && filteredPos.length === 0 && (
                <tr>
                  <td colSpan={8} className="sales-orders-empty">
                    No purchase orders yet.
                  </td>
                </tr>
              )}
              {!loading &&
                pagePos.map((po) => {
                  const status = statusMeta(po.Status);

                  return (
                    <tr key={po.PurchaseOrderId}>
                      <td className="mono">{po.PoNumber}</td>
                      <td className="sales-orders-date">
                        {fmtDate(po.OrderDate)}
                      </td>
                      <td className="sales-orders-customer">{po.Supplier}</td>
                      <td className="sales-orders-location">
                        {po.ShipToLocation}
                      </td>
                      <td style={{ textAlign: "center" }}>{po.LineCount}</td>
                      <td className="sales-orders-total">
                        {fmt(Number(po.TotalOrderedValue))}
                      </td>
                      <td>
                        <span
                          className="sales-orders-status"
                          style={{ color: status.color }}
                        >
                          {status.label}
                        </span>
                      </td>
                      <td style={{ minWidth: 140 }}>
                        <ProgressBar pct={Number(po.FulfilmentPct)} />
                      </td>
                    </tr>
                  );
                })}
            </tbody>
          </table>
        </div>

        <div className="sales-orders-footer">
          <button
            type="button"
            className="sales-orders-pagination-btn"
            onClick={() => setPage((current) => Math.max(1, current - 1))}
            disabled={page <= 1 || loading || filteredPos.length === 0}
          >
            Previous
          </button>

          <p className="sales-orders-details">
            <span>Page </span>
            <strong>{filteredPos.length === 0 ? 0 : page}</strong>
            <span> of {filteredPos.length === 0 ? 0 : totalPages}</span>
          </p>

          <button
            type="button"
            className="sales-orders-pagination-btn"
            onClick={() =>
              setPage((current) => Math.min(totalPages, current + 1))
            }
            disabled={page >= totalPages || loading || filteredPos.length === 0}
          >
            Next
          </button>
        </div>
      </div>
    </div>
  );
}

// ═════════════════════════════════════════════════════════════════════════════
// ROOT APP
// ═════════════════════════════════════════════════════════════════════════════
export default function App() {
  const [token, setToken] = useState<string>(
    () => localStorage.getItem("ashcol_token") ?? "",
  );
  const [user, setUser] = useState<User | null>(() => {
    try {
      return JSON.parse(localStorage.getItem("ashcol_user") ?? "null");
    } catch {
      return null;
    }
  });
  const [page, setPage] = useState<Page>("dashboard");
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const [theme, setTheme] = useState<"light" | "dark">((() => {
    const saved = localStorage.getItem("ashcol_theme");
    if (saved === "light" || saved === "dark") return saved;
    return window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light";
  }) as () => "light" | "dark");

  const api = useMemo(() => makeApi(token), [token]);

  useEffect(() => {
    document.documentElement.setAttribute("data-theme", theme);
    localStorage.setItem("ashcol_theme", theme);
  }, [theme]);

  const toggleTheme = () => setTheme((prev) => (prev === "light" ? "dark" : "light"));

  useEffect(() => {
    const handleResize = () => {
      if (window.innerWidth > 768) {
        setMobileMenuOpen(false);
      }
    };

    window.addEventListener("resize", handleResize);
    return () => window.removeEventListener("resize", handleResize);
  }, []);

  function handleLogin(newToken: string, newUser: User) {
    localStorage.setItem("ashcol_token", newToken);
    localStorage.setItem("ashcol_user", JSON.stringify(newUser));
    setToken(newToken);
    setUser(newUser);
    setPage("dashboard");
    setMobileMenuOpen(false);
  }

  function handleLogout() {
    localStorage.removeItem("ashcol_token");
    localStorage.removeItem("ashcol_user");
    setToken("");
    setUser(null);
    setMobileMenuOpen(false);
  }

  if (!token || !user) return <LoginPage onLogin={handleLogin} />;

  const pageComponent: Record<Page, React.ReactNode> = {
    dashboard: <DashboardPage />,
    products: <ProductsPage api={api} />,
    "sales-orders": <SalesOrdersPage api={api} />,
    invoices: <InvoicesPage api={api} />,
    "purchase-orders": <PurchaseOrdersPage api={api} />,
    "service-jobs": <ServiceJobsPage api={api} />,
  };

  return (
    <div className={`layout${mobileMenuOpen ? " sidebar-open" : ""}`}>
      <Sidebar
        page={page}
        setPage={setPage}
        onLogout={handleLogout}
        isOpen={mobileMenuOpen}
        onNavigate={() => setMobileMenuOpen(false)}
      />
      <button
        type="button"
        className={`sidebar-overlay${mobileMenuOpen ? " show" : ""}`}
        onClick={() => setMobileMenuOpen(false)}
        aria-label="Close navigation"
      />
      <div className="main-wrapper">
        <TopBar
          user={user}
          menuOpen={mobileMenuOpen}
          onToggleMenu={() => setMobileMenuOpen((prev) => !prev)}
          theme={theme}
          onToggleTheme={toggleTheme}
        />
        {pageComponent[page]}
      </div>
    </div>
  );
}
