
import { type LucideProps, Home, Notebook, Edit, Plus, File, FileText, FileUp, Image, SquarePen, MoreVertical, GripVertical, ChevronDown, Search, Settings, Trash2, Folder, Star, Share2, Clock, Tags, ArrowLeft, ArrowRight, Maximize, Minimize, X, Bold, Italic, Underline, Strikethrough, Code, List, ListOrdered, Quote, Link, Image as ImageIcon, CheckSquare, Mic, Paperclip, Palette, Columns, Rows, AlignLeft, AlignCenter, AlignRight, AlignJustify } from "lucide-react";

export const Icons = {
  home: Home,
  notebook: Notebook,
  edit: Edit,
  plus: Plus,
  file: File,
  fileText: FileText,
  fileUp: FileUp,
  image: Image,
  squarePen: SquarePen,
  moreVertical: MoreVertical,
  gripVertical: GripVertical,
  chevronDown: ChevronDown,
  search: Search,
  settings: Settings,
  trash: Trash2,
  folder: Folder,
  star: Star,
  share: Share2,
  history: Clock,
  tags: Tags,
  arrowLeft: ArrowLeft,
  arrowRight: ArrowRight,
  maximize: Maximize,
  minimize: Minimize,
  close: X,
  bold: Bold,
  italic: Italic,
  underline: Underline,
  strikethrough: Strikethrough,
  code: Code,
  ul: List,
  ol: ListOrdered,
  quote: Quote,
  link: Link,
  imageIcon: ImageIcon,
  checkSquare: CheckSquare,
  mic: Mic,
  paperclip: Paperclip,
  palette: Palette,
  columns: Columns,
  rows: Rows,
  alignLeft: AlignLeft,
  alignCenter: AlignCenter,
  alignRight: AlignRight,
  alignJustify: AlignJustify,
};

export type Icon = keyof typeof Icons;

export const Icon = ({
  name,
  ...props
}: { name: Icon } & LucideProps) => {
  const LucideIcon = Icons[name];
  return <LucideIcon {...props} />;
};
