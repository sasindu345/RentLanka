interface InputProps extends React.InputHTMLAttributes<HTMLInputElement> {
  label?: string;
}

export function Input({ label, className = "", id, ...props }: InputProps) {
  const inputId = id ?? label?.toLowerCase().replace(/\s+/g, "-");
  return (
    <label className="flex flex-col gap-1.5 text-sm">
      {label && <span className="font-medium text-foreground">{label}</span>}
      <input
        id={inputId}
        className={`rounded-xl border border-border bg-background px-4 py-2.5 outline-none focus:border-primary ${className}`}
        {...props}
      />
    </label>
  );
}
