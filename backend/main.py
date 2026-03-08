import base64
import os
from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from langchain_anthropic import ChatAnthropic
from langchain_core.messages import HumanMessage
from pydantic import BaseModel
from dotenv import load_dotenv
from langchain_core.messages import HumanMessage, SystemMessage


load_dotenv()

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


class ReceiptItem(BaseModel):
    name: str
    price: int
    quantity: int
    category: str


class ReceiptResponse(BaseModel):
    store_name: str
    date: str
    total_amount: int
    items: list[ReceiptItem]


llm = ChatAnthropic(model="claude-sonnet-4-6")
structured_llm = llm.with_structured_output(ReceiptResponse)

PROMPT = """以下のレシート画像を解析してください。

categoryは以下から最も適切なものを選んでください:
食費, 外食, 日用品, 交通, 医療, 娯楽, その他

日付が読み取れない場合は今日の日付を使用してください。
金額は税込みで記載してください。"""


@app.post("/analyze-receipt", response_model=ReceiptResponse)
async def analyze_receipt(image: UploadFile = File(...)):
    if not image.content_type or not image.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="画像ファイルを送信してください")

    image_data = await image.read()
    base64_image = base64.b64encode(image_data).decode("utf-8")

    message = HumanMessage(content=[
        {
            "type": "image",
            "source": {
                "type": "base64",
                "media_type": image.content_type,
                "data": base64_image,
            },
        },
        {
            "type": "text",
            "text": PROMPT,
        },
    ])

    result = await structured_llm.ainvoke([message])
    return result



class ReceiptItemSummary(BaseModel):
    name: str
    price: int
    quantity: int
    category: str

class ReceiptSummary(BaseModel):
    store_name: str
    date: str
    total_amount: int
    items: list[ReceiptItemSummary]

class ChatRequest(BaseModel):
    message: str
    receipts: list[ReceiptSummary]

class ChatResponse(BaseModel):
    reply: str


@app.post("/chat", response_model=ChatResponse)
async def chat(request: ChatRequest) -> ChatResponse:
    receipts_lines = []
    for r in request.receipts:
        receipts_lines.append(f"【{r.date} {r.store_name} 合計¥{r.total_amount}】")
        for item in r.items:
            receipts_lines.append(f"  - {item.name} ¥{item.price}×{item.quantity} ({item.category})")
    receipts_text = "\n".join(receipts_lines) if receipts_lines else "データなし"

    system_prompt = f"""あなたは家計簿アシスタントです。ユーザーの家計データをもとに、親切で具体的なアドバイスをしてください。
回答は日本語で、簡潔にお願いします。

家計データ:
{receipts_text}
"""

    response = await llm.ainvoke([
        SystemMessage(content=system_prompt),
        HumanMessage(content=request.message),
    ])
    return ChatResponse(reply=response.content)
